# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::HooksWorker, feature_category: :continuous_delivery do
  let(:worker) { described_class.new }

  describe '#perform' do
    before do
      allow(Integrations::ExecuteWorker).to receive(:perform_async)
    end

    it 'logs deployment and project IDs as metadata' do
      deployment = create(:deployment, :running)
      project = deployment.project

      expect(worker).to receive(:log_extra_metadata_on_done).with(:deployment_project_id, project.id)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:deployment_id, deployment.id)

      worker.perform(deployment_id: deployment.id, status_changed_at: Time.current)
    end

    it 'executes project services for deployment_hooks' do
      deployment = create(:deployment, :running)
      project = deployment.project
      service = create(:integrations_slack, project: project, deployment_events: true)

      expect(Integrations::ExecuteWorker).to receive(:perform_async).with(service.id, an_instance_of(Hash))

      worker.perform(deployment_id: deployment.id, status_changed_at: Time.current)
    end

    it 'does not execute an inactive service' do
      deployment = create(:deployment, :running)
      project = deployment.project
      create(:integrations_slack, project: project, deployment_events: true, active: false)

      expect(Integrations::ExecuteWorker).not_to receive(:perform_async)

      worker.perform(deployment_id: deployment.id, status_changed_at: Time.current)
    end

    it 'does not execute if a deployment does not exist' do
      expect(Integrations::ExecuteWorker).not_to receive(:perform_async)

      worker.perform(deployment_id: non_existing_record_id, status_changed_at: Time.current)
    end

    it 'execute webhooks' do
      deployment = create(:deployment, :running)
      project = deployment.project
      web_hook = create(:project_hook, deployment_events: true, project: project)

      status_changed_at = Time.current

      expect_next_instance_of(
        WebHookService,
        web_hook,
        hash_including(status_changed_at: status_changed_at),
        "deployment_hooks",
        idempotency_key: anything
      ) do |service|
        expect(service).to receive(:async_execute)
      end

      worker.perform(deployment_id: deployment.id, status_changed_at: status_changed_at)
    end

    it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed
  end
end
