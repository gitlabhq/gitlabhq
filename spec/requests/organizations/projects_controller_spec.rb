# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::ProjectsController, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:project) { create(:project, organization: organization) }

  describe 'GET #edit' do
    context 'when project exists' do
      subject(:gitlab_request) do
        get edit_namespace_projects_organization_path(
          project.organization,
          id: project.to_param,
          namespace_id: project.namespace.to_param
        )
      end

      context 'when the user is not signed in' do
        it_behaves_like 'organization - redirects to sign in page'

        context 'when `ui_for_organizations` feature flag is disabled' do
          before do
            stub_feature_flags(ui_for_organizations: false)
          end

          it_behaves_like 'organization - redirects to sign in page'
        end
      end

      context 'when the user is signed in' do
        let_it_be(:user) { create(:user) }

        before do
          sign_in(user)
        end

        context 'as as admin', :enable_admin_mode do
          let_it_be(:user) { create(:admin) }

          it_behaves_like 'organization - successful response'
          it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
        end

        context 'as a project maintainer' do
          before_all do
            project.add_maintainer(user)
          end

          it_behaves_like 'organization - successful response'
          it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
        end

        context 'as a user that is not a maintainer' do
          it_behaves_like 'organization - not found response'
          it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
        end
      end
    end

    context 'when project does not exist' do
      subject(:gitlab_request) do
        get edit_namespace_projects_organization_path(
          organization,
          id: 'project_that_does_not_exist',
          namespace_id: 'namespace_that_does_not_exist'
        )
      end

      context 'when the user is not signed in' do
        it_behaves_like 'organization - redirects to sign in page'
      end

      context 'when the user is signed in' do
        let_it_be(:user) { create(:user) }

        before do
          sign_in(user)
        end

        it_behaves_like 'organization - not found response'
      end
    end
  end
end
