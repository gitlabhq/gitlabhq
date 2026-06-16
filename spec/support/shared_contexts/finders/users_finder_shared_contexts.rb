# frozen_string_literal: true

RSpec.shared_context 'UsersFinder#execute filter by project context' do
  let_it_be(:normal_user, freeze: false) { create(:user, username: 'johndoe') }
  let_it_be(:admin_user, freeze: false) { create(:user, :admin, username: 'iamadmin') }
  let_it_be(:banned_user, freeze: false) { create(:user, :banned, username: 'iambanned') }
  let_it_be(:blocked_user, freeze: false) { create(:user, :blocked, username: 'notsorandom') }
  let_it_be(:external_user, freeze: false) { create(:user, :external) }
  let_it_be(:unconfirmed_user, freeze: false) { create(:user, confirmed_at: nil) }
  let_it_be(:omniauth_user, freeze: false) { create(:omniauth_user, provider: 'twitter', extern_uid: '123456') }
  let_it_be(:internal_user, freeze: false) do
    Users::Internal.in_organization(normal_user.organization).alert_bot.tap { |u| u.confirm }
  end
end
