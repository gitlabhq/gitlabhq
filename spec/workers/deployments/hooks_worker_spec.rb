# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::HooksWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    before do
      allow(ProjectServiceWorker).to receive(:perform_async)
    end

    it 'executes project services for deployment_hooks' do
      deployment = create(:deployment, :running)
      project = deployment.project
      service = create(:service, type: 'SlackService', project: project, deployment_events: true, active: true)

      expect(ProjectServiceWorker).to receive(:perform_async).with(service.id, an_instance_of(Hash))

      worker.perform(deployment_id: deployment.id, status_changed_at: Time.current)
    end

    it 'does not execute an inactive service' do
      deployment = create(:deployment, :running)
      project = deployment.project
      create(:service, type: 'SlackService', project: project, deployment_events: true, active: false)

      expect(ProjectServiceWorker).not_to receive(:perform_async)

      worker.perform(deployment_id: deployment.id, status_changed_at: Time.current)
    end

    it 'does not execute if a deployment does not exist' do
      expect(ProjectServiceWorker).not_to receive(:perform_async)

      worker.perform(deployment_id: non_existing_record_id, status_changed_at: Time.current)
    end

    it 'execute webhooks' do
      deployment = create(:deployment, :running)
      project = deployment.project
      web_hook = create(:project_hook, deployment_events: true, project: project)

      status_changed_at = Time.current

      expect_next_instance_of(WebHookService, web_hook, hash_including(status_changed_at: status_changed_at), "deployment_hooks") do |service|
        expect(service).to receive(:async_execute)
      end

      worker.perform(deployment_id: deployment.id, status_changed_at: status_changed_at)
    end
  end
end
