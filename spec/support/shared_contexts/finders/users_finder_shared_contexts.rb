# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_context 'UsersFinder#execute filter by project context' do
  set(:normal_user) { create(:user, username: 'johndoe') }
  set(:blocked_user) { create(:user, :blocked, username: 'notsorandom') }
  set(:external_user) { create(:user, :external) }
  set(:omniauth_user) { create(:omniauth_user, provider: 'twitter', extern_uid: '123456') }
end
