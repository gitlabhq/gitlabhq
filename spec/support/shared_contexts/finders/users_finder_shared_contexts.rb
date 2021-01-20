# frozen_string_literal: true

RSpec.shared_context 'UsersFinder#execute filter by project context' do
  let_it_be(:normal_user) { create(:user, username: 'johndoe') }
  let_it_be(:admin_user) { create(:user, :admin, username: 'iamadmin') }
  let_it_be(:blocked_user) { create(:user, :blocked, username: 'notsorandom') }
  let_it_be(:external_user) { create(:user, :external) }
  let_it_be(:omniauth_user) { create(:omniauth_user, provider: 'twitter', extern_uid: '123456') }
  let_it_be(:internal_user) { User.alert_bot }
end
