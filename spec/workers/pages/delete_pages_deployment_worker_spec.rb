# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DeletePagesDeploymentWorker, feature_category: :pages do
  let_it_be(:project) { create(:project) }
  let!(:pages_deployment) { create(:pages_deployment, project: project) }

  let(:event) do
    ::Projects::ProjectArchivedEvent.new(data: {
      project_id: project.id,
      namespace_id: project.namespace.id,
      root_namespace_id: project.root_namespace.id
    })
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :always
  it_behaves_like 'subscribes to event'

  subject(:use_event) { consume_event(subscriber: described_class, event: event) }

  it 'marks pages as not deployed' do
    project.update!(archived: true)

    expect { use_event }
      .to change { project.reload.pages_deployed? }
            .from(true).to(false)
  end

  it 'removes pages deployments', :sidekiq_inline do
    project.update!(archived: true)

    expect { use_event }
      .to change { PagesDeployment.count }.by(-1)
  end
end
