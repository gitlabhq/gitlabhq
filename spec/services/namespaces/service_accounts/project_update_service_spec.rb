# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ServiceAccounts::ProjectUpdateService, feature_category: :user_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:other_project) { create(:project, group: group) }
  let_it_be(:project_owner) { create(:user) }
  let_it_be(:project_maintainer) { create(:user) }
  let_it_be(:project_developer) { create(:user) }

  let(:service_account_user) { create(:user, :service_account, provisioned_by_project_id: project.id) }

  let(:params) do
    {
      name: FFaker::Name.name,
      username: "service_account_#{SecureRandom.hex(8)}",
      email: FFaker::Internet.email,
      project_id: project.id
    }
  end

  subject(:service) { described_class.new(current_user, service_account_user, params) }

  before_all do
    project.add_owner(project_owner)
    project.add_maintainer(project_maintainer)
    project.add_developer(project_developer)
  end

  describe '#execute' do
    context 'when current user is a project owner' do
      let(:current_user) { project_owner }

      it_behaves_like 'service account update success'
    end

    context 'when current user is a project maintainer' do
      let(:current_user) { project_maintainer }

      it_behaves_like 'service account update success'

      context 'when params are empty' do
        let(:params) { {} }

        it 'returns a project not found error', :aggregate_failures do
          result = service.execute

          expect(result.status).to eq(:error)
          expect(result.message).to eq(s_('ServiceAccount|Project with the provided ID not found.'))
          expect(result.reason).to eq(:not_found)
        end
      end

      context 'when the provided project id does not match the service account project' do
        let(:params) { super().merge(project_id: other_project.id) }

        it 'returns an invalid project id error', :aggregate_failures do
          result = service.execute

          expect(result.status).to eq(:error)
          expect(result.message).to eq(
            s_("ServiceAccount|Project ID provided does not match the service account's project ID.")
          )
          expect(result.reason).to eq(:bad_request)
        end
      end

      context 'when project_id does not exist' do
        let(:params) { super().merge(project_id: non_existing_record_id) }

        it 'returns a project not found error', :aggregate_failures do
          result = service.execute

          expect(result.status).to eq(:error)
          expect(result.message).to eq(s_('ServiceAccount|Project with the provided ID not found.'))
          expect(result.reason).to eq(:not_found)
        end
      end
    end

    context 'when current user is a project developer' do
      let(:current_user) { project_developer }

      it_behaves_like 'service account update not authorized'
    end
  end
end
