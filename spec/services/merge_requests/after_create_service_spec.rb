# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::AfterCreateService do
  let_it_be(:merge_request) { create(:merge_request) }

  subject(:after_create_service) do
    described_class.new(merge_request.target_project, merge_request.author)
  end

  describe '#execute' do
    let(:event_service) { instance_double('EventCreateService', open_mr: true) }
    let(:notification_service) { instance_double('NotificationService', new_merge_request: true) }

    before do
      allow(after_create_service).to receive(:event_service).and_return(event_service)
      allow(after_create_service).to receive(:notification_service).and_return(notification_service)
    end

    subject(:execute_service) { after_create_service.execute(merge_request) }

    it 'creates a merge request open event' do
      expect(event_service)
        .to receive(:open_mr).with(merge_request, merge_request.author)

      execute_service
    end

    it 'calls the merge request activity counter' do
      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
        .to receive(:track_create_mr_action)
        .with(user: merge_request.author)

      execute_service
    end

    it 'creates a new merge request notification' do
      expect(notification_service)
        .to receive(:new_merge_request).with(merge_request, merge_request.author)

      execute_service
    end

    it 'writes diffs to the cache' do
      expect(merge_request)
        .to receive_message_chain(:diffs, :write_cache)

      execute_service
    end

    it 'creates cross references' do
      expect(merge_request)
        .to receive(:create_cross_references!).with(merge_request.author)

      execute_service
    end

    it 'creates a pipeline and updates the HEAD pipeline' do
      expect(after_create_service)
        .to receive(:create_pipeline_for).with(merge_request, merge_request.author)
      expect(merge_request).to receive(:update_head_pipeline)

      execute_service
    end

    it 'records a namespace onboarding progress action' do
      expect(NamespaceOnboardingAction).to receive(:create_action)
        .with(merge_request.target_project.namespace, :merge_request_created).and_call_original

      expect { execute_service }.to change(NamespaceOnboardingAction, :count).by(1)
    end
  end
end
