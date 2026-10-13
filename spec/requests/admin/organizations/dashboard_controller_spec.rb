# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Organizations::DashboardController, feature_category: :organization do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:other_organization) { create(:organization) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:organization_owner) { create(:user, :organization_owner, organization: organization) }
  let_it_be(:regular_user) { create(:user) }

  # Use without_current_organization metadata to ensure current organization isn't stubbed.
  # This enables testing Current.organization resolution from path params.
  describe 'GET /o/:organization_path/admin', :without_current_organization do
    subject(:request) { get organization_admin_root_path(organization) }

    let(:other_organization_request) { get organization_admin_root_path(other_organization) }

    it_behaves_like 'an organization admin area request'

    context 'when user is an instance admin', :enable_admin_mode do
      before do
        sign_in(admin)
      end

      it 'renders the organization admin dashboard content' do
        request

        expect(response.body).to include(_('Organization overview'))
      end
    end

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'renders the organization admin dashboard content' do
        request

        expect(response.body).to include(_('Organization overview'))
      end

      context 'with records scoped to the organization' do
        let_it_be(:project) { create(:project, organization: organization) }
        let_it_be(:group) { create(:group, organization: organization) }
        let_it_be(:member) { create(:user, :with_namespace, organization: organization) }

        let_it_be(:other_project) { create(:project, organization: other_organization) }
        let_it_be(:other_group) { create(:group, organization: other_organization) }
        let_it_be(:other_member) { create(:user, :with_namespace, organization: other_organization) }

        it 'shows records belonging to the organization' do
          request

          expect(response.body).to include(project.full_name)
          expect(response.body).to include(group.full_name)
          expect(response.body).to include(member.name)
        end

        it 'does not show records belonging to another organization' do
          request

          expect(response.body).not_to include(other_project.full_name)
          expect(response.body).not_to include(other_group.full_name)
          expect(response.body).not_to include(other_member.name)
        end

        context 'when a count is unavailable' do
          before do
            allow(Gitlab::Database::Count).to receive(:approximate_counts_for_organization)
              .and_return({ User => 1, Group => 1 })
          end

          it 'still renders the page with a fallback for the missing count' do
            get organization_admin_root_path(organization)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.body).to include(_('This count is currently unavailable.'))
          end
        end
      end

      context 'when X-GitLab-Organization-ID header is provided' do
        it 'uses organization from path, not header' do
          header_organization = create(:organization)

          get organization_admin_root_path(organization),
            headers: { 'X-GitLab-Organization-ID' => header_organization.id.to_s }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end
end
