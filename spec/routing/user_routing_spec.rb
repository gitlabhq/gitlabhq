# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user routing', :clean_gitlab_redis_sessions, feature_category: :system_access do
  include SessionHelpers

  context 'when GitHub OAuth on project import is cancelled' do
    it_behaves_like 'redirecting a legacy path', '/users/auth?error=access_denied&state=xyz', '/users/sign_in'
  end

  context 'when GitHub OAuth on sign in is cancelled' do
    before do
      stub_session(session_data: { auth_on_failure_path: '/projects/new#import_project' })
    end

    context 'when all required parameters are present' do
      it_behaves_like 'redirecting a legacy path',
        '/users/auth?error=access_denied&state=xyz',
        '/projects/new#import_project'
    end

    context 'when one of the required parameters is missing' do
      it_behaves_like 'redirecting a legacy path',
        '/users/auth?error=access_denied&state=',
        '/auth'
    end
  end
end

RSpec.describe "Users", "routing", feature_category: :user_management do
  let!(:user) { create(:user) }

  describe 'GET /-/u/:id' do
    it 'routes to users/redirect#redirect_from_id' do
      expect(get('/-/u/1')).to route_to('users/redirect#redirect_from_id', id: '1')
    end
  end
end
