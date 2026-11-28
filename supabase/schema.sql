-- =============================================================================
-- TrilhaGO — Supabase (PostgreSQL + PostGIS) Schema & Atomic RPCs
-- =============================================================================

create extension if not exists postgis;
create extension if not exists pgcrypto;

-- 1. Equipes
create table if not exists public.teams (
  id text primary key,
  name text not null,
  color_hex text not null,
  total_territories integer not null default 0
);

insert into public.teams (id, name, color_hex) values
  ('esmeralda', 'Esmeralda', '#10B981'),
  ('horizonte', 'Horizonte', '#0EA5E9'),
  ('solar', 'Solar', '#F59E0B')
on conflict (id) do nothing;

-- 2. Perfis de Jogadores
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  display_name text not null default 'Explorador',
  team_id text references public.teams(id),
  avatar_id integer not null default 1 check (avatar_id between 1 and 9),
  keys_count integer not null default 3 check (keys_count >= 0),
  xp integer not null default 0,
  coins integer not null default 0,
  total_distance_m double precision not null default 0,
  created_at timestamptz not null default now()
);

-- 3. Territórios Hexagonais (H3 Resolução 9/10)
create table if not exists public.territories (
  h3_index text primary key,
  resolution integer not null default 9 check (resolution in (9, 10)),
  owner_team_id text references public.teams(id),
  owner_user_id uuid references public.profiles(id),
  points integer not null default 0,
  geom geography(Polygon, 4326),
  updated_at timestamptz not null default now()
);

create index if not exists idx_territories_geom on public.territories using gist (geom);

-- 4. Lojas Parceiras & Baús
create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'Comércio Local',
  photo_url text,
  location geography(Point, 4326) not null,
  has_premium_chest boolean not null default true,
  -- Janela de expediente (nunca 00:00) para liberar o 1 Baú Premium do dia
  premium_window_start time not null default '09:30:00',
  premium_window_end time not null default '18:30:00',
  last_premium_awarded_date date,
  cooldown_days integer not null default 10 check (cooldown_days between 7 and 15),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists idx_stores_location on public.stores using gist (location);

-- 5. Estoque de Prêmios por Loja
create table if not exists public.store_rewards (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  rarity text not null check (rarity in ('common', 'rare', 'premium')),
  title text not null,
  description text,
  stock integer not null default 10 check (stock >= 0)
);

-- 6. Cooldown por Usuário x Loja (7 a 15 dias para Premium)
create table if not exists public.user_store_cooldowns (
  user_id uuid not null references public.profiles(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  eligible_after timestamptz not null,
  primary key (user_id, store_id)
);

-- 7. Mochila: Cupons com QR Code único
create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  rarity text not null check (rarity in ('common', 'rare', 'premium')),
  reward_title text not null,
  qr_token text not null unique default encode(gen_random_bytes(12), 'hex'),
  created_at timestamptz not null default now(),
  redeemed_at timestamptz
);

-- 8. Histórico de Treinos (Modo Esporte)
create table if not exists public.workouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  mode text not null check (mode in ('walk', 'run', 'bike')),
  distance_m double precision not null,
  duration_s integer not null,
  calories integer not null,
  avg_pace_min_km double precision,
  keys_earned integer not null default 0,
  xp_earned integer not null default 0,
  route_geojson jsonb,
  created_at timestamptz not null default now()
);

-- =============================================================================
-- RPC Atômica: Abertura de Baú com trava 40m + 1 Premium/dia + Cooldown 7-15d
-- =============================================================================
create or replace function public.claim_chest_reward(
  p_user_id uuid,
  p_store_id uuid,
  p_user_lat double precision,
  p_user_lng double precision,
  p_key_cost integer default 1
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_store public.stores%rowtype;
  v_profile public.profiles%rowtype;
  v_distance_m double precision;
  v_now_time time := (now() at time zone 'America/Sao_Paulo')::time;
  v_today date := (now() at time zone 'America/Sao_Paulo')::date;
  v_cooldown timestamptz;
  v_roll double precision := random();
  v_rarity text;
  v_reward public.store_rewards%rowtype;
  v_qr text;
begin
  select * into v_store from public.stores where id = p_store_id and active = true for update;
  if not found then
    return jsonb_build_object('ok', false, 'error', 'Loja não encontrada.');
  end if;

  select * into v_profile from public.profiles where id = p_user_id for update;
  if not found then
    return jsonb_build_object('ok', false, 'error', 'Perfil não encontrado.');
  end if;

  if v_profile.keys_count < p_key_cost then
    return jsonb_build_object('ok', false, 'error', 'Chaves insuficientes.');
  end if;

  v_distance_m := st_distance(
    v_store.location,
    st_setsrid(st_makepoint(p_user_lng, p_user_lat), 4326)::geography
  );

  if v_distance_m > 40.0 then
    return jsonb_build_object('ok', false, 'error', 'Aproxime-se a menos de 40m da loja.');
  end if;

  -- Sorteio: Premium 5% | Raro 25% | Comum 70%
  if v_roll < 0.05 and v_store.has_premium_chest
     and v_now_time between v_store.premium_window_start and v_store.premium_window_end
     and (v_store.last_premium_awarded_date is null or v_store.last_premium_awarded_date < v_today) then

    select eligible_after into v_cooldown
      from public.user_store_cooldowns
     where user_id = p_user_id and store_id = p_store_id;

    if v_cooldown is null or v_cooldown <= now() then
      v_rarity := 'premium';
    else
      v_rarity := 'rare';
    end if;
  elsif v_roll < 0.30 then
    v_rarity := 'rare';
  else
    v_rarity := 'common';
  end if;

  -- Busca prêmio com estoque disponível
  select * into v_reward
    from public.store_rewards
   where store_id = p_store_id and rarity = v_rarity and stock > 0
   order by random() limit 1
   for update;

  if not found then
    v_rarity := 'common';
    select * into v_reward
      from public.store_rewards
     where store_id = p_store_id and rarity = 'common' and stock > 0
     order by random() limit 1
     for update;
  end if;

  -- Desconta chave
  update public.profiles
     set keys_count = keys_count - p_key_cost,
         xp = xp + case when v_rarity = 'premium' then 150 when v_rarity = 'rare' then 60 else 25 end,
         coins = coins + case when v_rarity = 'common' then 50 else 15 end
   where id = p_user_id;

  if v_rarity = 'premium' then
    update public.stores set last_premium_awarded_date = v_today where id = p_store_id;
    insert into public.user_store_cooldowns (user_id, store_id, eligible_after)
    values (p_user_id, p_store_id, now() + (v_store.cooldown_days || ' days')::interval)
    on conflict (user_id, store_id) do update
      set eligible_after = excluded.eligible_after;
  end if;

  if found then
    update public.store_rewards set stock = stock - 1 where id = v_reward.id;
    insert into public.coupons (user_id, store_id, rarity, reward_title)
    values (p_user_id, p_store_id, v_rarity, v_reward.title)
    returning qr_token into v_qr;
  else
    v_qr := null;
  end if;

  return jsonb_build_object(
    'ok', true,
    'rarity', v_rarity,
    'reward_title', coalesce(v_reward.title, '+50 Moedas e +25 XP'),
    'qr_token', v_qr
  );
end;
$$;

-- =============================================================================
-- RPC: Validação de QR Code pelo Painel Web do Lojista
-- =============================================================================
create or replace function public.validate_store_qr(
  p_store_id uuid,
  p_qr_token text
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_coupon public.coupons%rowtype;
begin
  select * into v_coupon
    from public.coupons
   where store_id = p_store_id and qr_token = p_qr_token
   for update;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'QR Code inválido para esta loja.');
  end if;

  if v_coupon.redeemed_at is not null then
    return jsonb_build_object('ok', false, 'error', 'Cupom já resgatado anteriormente.');
  end if;

  update public.coupons set redeemed_at = now() where id = v_coupon.id;
  return jsonb_build_object(
    'ok', true,
    'reward_title', v_coupon.reward_title,
    'rarity', v_coupon.rarity
  );
end;
$$;
