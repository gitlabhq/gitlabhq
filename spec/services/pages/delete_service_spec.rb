# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DeleteService, feature_category: :pages do
  let_it_be(:user) { create(:user) }
  let(:project) { create(:project, path: "my.project") }
  let(:service) { described_class.new(project, user) }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    context 'when user has permission' do
      it 'marks pages as not deployed' do
        create(:pages_deployment, project: project)

        expect { service.execute }.to change { project.pages_deployed? }.from(true).to(false)
      end

      it 'deletes domains' do
        domain = create(:pages_domain, project: project)
        other_domain = create(:pages_domain)

        expect { service.execute }.to change { PagesDomain.count }.by(-1)
        expect { domain.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { other_domain.reload }.not_to raise_error
      end

      it 'schedules destruction of pages deployments' do
        expect(DestroyPagesDeploymentsWorker).to receive(:perform_async).with(project.id)

        service.execute
      end

      it 'removes pages deployments', :sidekiq_inline do
        create(:pages_deployment, project: project)

        expect { service.execute }.to change { PagesDeployment.count }.by(-1)
      end

      it 'publishes a ProjectDeleted event with project id and namespace id' do
        expected_data = {
          project_id: project.id,
          namespace_id: project.namespace_id,
          root_namespace_id: project.root_namespace.id
        }

        expect { service.execute }.to publish_event(Pages::PageDeletedEvent).with(expected_data)
      end
    end

    context 'when user does not have permission' do
      before do
        project.add_developer(user)
      end

      it 'does not delete pages' do
        expect { service.execute }.not_to change { project.pages_deployed? }
      end

      it 'returns an error message' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('The current user is not authorized to remove the Pages deployment')
      end
    end
  end
end
