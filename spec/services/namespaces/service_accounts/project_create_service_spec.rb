# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ServiceAccounts::ProjectCreateService, feature_category: :user_management do
  shared_examples 'service account creation failure for project' do
    it 'produces an error', :aggregate_failures do
      expect(result.status).to eq(:error)
      expect(result.message).to eq(
        s_('ServiceAccount|User does not have permission to create a service account in this project.')
      )
    end
  end

  let_it_be(:organization) { create(:organization) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let(:project_id) { project.id }

  subject(:service) do
    described_class.new(current_user, { organization_id: organization.id, project_id: project_id })
  end

  context 'when current user is an admin', :enable_admin_mode do
    let_it_be(:current_user) { create(:admin) }

    it_behaves_like 'service account creation success' do
      let(:username_prefix) { "service_account_project_#{project.id}" }
    end

    it 'sets provisioned by project' do
      expect(result.payload[:user].provisioned_by_project_id).to eq(project.id)
    end

    it 'does not set provisioned by group' do
      expect(result.payload[:user].provisioned_by_group_id).to be_nil
    end

    context 'when the project is invalid' do
      let(:project_id) { non_existing_record_id }

      it_behaves_like 'service account creation failure for project'
    end
  end

  # Use non-admin roles below to exercise the real authorization path - admin bypasses
  # policy checks entirely.
  context 'when current user is not an admin' do
    context 'when a project developer' do
      let_it_be(:current_user) { create(:user, developer_of: project) }

      it_behaves_like 'service account creation failure for project'
    end
  end

  describe 'skip_owner_check does not apply to projects' do
    let_it_be(:current_user) { create(:user, developer_of: project) }

    subject(:service) do
      described_class.new(current_user, {
        organization_id: organization.id, project_id: project_id,
        skip_owner_check: true, composite_identity_enforced: true
      })
    end

    it 'does not bypass permission checks for project-level service accounts' do
      expect(result.status).to eq(:error)
      expect(result.message).to eq(
        s_('ServiceAccount|User does not have permission to create a service account in this project.')
      )
    end
  end

  def result
    service.execute
  end
end
