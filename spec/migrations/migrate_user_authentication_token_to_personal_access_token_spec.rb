require 'spec_helper'
require Rails.root.join('db', 'migrate', '20171012125712_migrate_user_authentication_token_to_personal_access_token.rb')

describe MigrateUserAuthenticationTokenToPersonalAccessToken, :migration do
  let(:users) { table(:users) }
  let(:personal_access_tokens) { table(:personal_access_tokens) }

  let!(:user) { users.create!(id: 1, email: 'user@example.com', authentication_token: 'user-token', admin: false) }
  let!(:admin) { users.create!(id: 2, email: 'admin@example.com', authentication_token: 'admin-token', admin: true) }

  it 'migrates private tokens to Personal Access Tokens' do
    migrate!

    expect(personal_access_tokens.count).to eq(2)

    user_token = personal_access_tokens.find_by(user_id: user.id)
    admin_token = personal_access_tokens.find_by(user_id: admin.id)

    expect(user_token.token).to eq('user-token')
    expect(admin_token.token).to eq('admin-token')

    expect(user_token.scopes).to eq(%w[api].to_yaml)
    expect(admin_token.scopes).to eq(%w[api sudo].to_yaml)
  end
end
