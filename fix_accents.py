import os

def fix_file(filepath):
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()
    
    content = content.replace("Usuǭrio nǜo encontrado.", "Usuário não encontrado.")
    content = content.replace("Localizaǜo obtida com sucesso!", "Localização obtida com sucesso!")
    content = content.replace("11 nmeros", "11 números")
    content = content.replace("invlido", "inválido")
    content = content.replace("nmeros", "números")
    content = content.replace("j est", "já está")
    content = content.replace("usurio", "usuário")
    content = content.replace("mnimo", "mínimo")
    content = content.replace("Retirada em mǜos", "Retirada em mãos")
    content = content.replace("decoraǜo", "decoração")
    content = content.replace("Eletrnicos", "Eletrônicos")
    content = content.replace("EletrodomǸsticos", "Eletrodomésticos")
    content = content.replace("calados", "calçados")
    content = content.replace("Veculos", "Veículos")
    content = content.replace("CosmǸticos", "Cosméticos")
    content = content.replace("Sǜo Paulo", "São Paulo")
    content = content.replace("versǜo", "versão")
    content = content.replace("Notificaes permitidas", "Notificações permitidas")
    content = content.replace("permissǜo", "permissão")
    content = content.replace("Nenhuma notificaǜo por enquanto.", "Nenhuma notificação por enquanto.")
    content = content.replace("Atenǜo", "Atenção")
    
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

for root, _, files in os.walk("ViewModels"):
    for file in files:
        if file.endswith(".swift"):
            fix_file(os.path.join(root, file))

for root, _, files in os.walk("Views"):
    for file in files:
        if file.endswith(".swift"):
            fix_file(os.path.join(root, file))

for root, _, files in os.walk("Services"):
    for file in files:
        if file.endswith(".swift"):
            fix_file(os.path.join(root, file))
