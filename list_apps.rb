require 'spaceship'

token = Spaceship::ConnectAPI::Token.create(
  key_id: ENV['APPSTORE_KEY_ID'],
  issuer_id: ENV['APPSTORE_ISSUER_ID'],
  filepath: File.expand_path("C:/Users/KENEDI/Downloads/AuthKey_#{ENV['APPSTORE_KEY_ID']}.p8")
)
Spaceship::ConnectAPI.token = token

apps = Spaceship::ConnectAPI::App.all
apps.each do |app|
  puts "App Name: #{app.name} | Bundle ID: #{app.bundle_id} | Apple ID: #{app.id}"
end
