# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::ServiceAccountsController, feature_category: :user_management do
  include AdminModeHelper
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }

  shared_examples 'page is not found' do
    it 'has correct status' do
      get_request

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'redirects to login' do
    it 'redirects to sign in page' do
      get_request

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  shared_examples 'page is found' do
    it 'returns a 200 status code' do
      get_request

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  shared_examples 'access control' do
    shared_examples 'page is found under proper conditions' do
      it_behaves_like 'page is found'
    end

    context 'when not logged in' do
      it_behaves_like 'redirects to login'
    end

    context 'with different access levels not allowed' do
      where(access_level: [nil, :guest, :reporter, :developer])

      with_them do
        before do
          project.add_member(user, access_level) if access_level
          sign_in(user)
        end

        it_behaves_like 'page is not found'
      end
    end

    context 'with admins' do
      before do
        sign_in(admin)
        enable_admin_mode!(admin)
      end

      it_behaves_like 'page is found under proper conditions'
    end

    context 'with project maintainers' do
      before_all do
        project.add_maintainer(user)
      end

      before do
        sign_in(user)
      end

      it_behaves_like 'page is found under proper conditions'
    end

    context 'with group owners' do
      before_all do
        group.add_owner(user)
      end

      before do
        sign_in(user)
      end

      it_behaves_like 'page is found under proper conditions'
    end
  end

  describe 'GET #index' do
    subject(:get_request) { get(project_settings_service_accounts_path(project)) }

    it_behaves_like 'access control'
  end
end
