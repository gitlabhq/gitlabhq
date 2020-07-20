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

    it 'creates a merge request open event' do
      expect(event_service)
        .to receive(:open_mr).with(merge_request, merge_request.author)

      after_create_service.execute(merge_request)
    end

    it 'creates a new merge request notification' do
      expect(notification_service)
        .to receive(:new_merge_request).with(merge_request, merge_request.author)

      after_create_service.execute(merge_request)
    end

    it 'writes diffs to the cache' do
      expect(merge_request)
        .to receive_message_chain(:diffs, :write_cache)

      after_create_service.execute(merge_request)
    end

    it 'creates cross references' do
      expect(merge_request)
        .to receive(:create_cross_references!).with(merge_request.author)

      after_create_service.execute(merge_request)
    end

    it 'creates a pipeline and updates the HEAD pipeline' do
      expect(after_create_service)
        .to receive(:create_pipeline_for).with(merge_request, merge_request.author)
      expect(merge_request).to receive(:update_head_pipeline)

      after_create_service.execute(merge_request)
    end
  end
end
