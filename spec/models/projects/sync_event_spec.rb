# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::SyncEvent, feature_category: :cell do
  it_behaves_like 'a database sync event table', :project

  describe '.enqueue_worker' do
    it 'schedules Projects::ProcessSyncEventsWorker job' do
      expect(::Projects::ProcessSyncEventsWorker).to receive(:perform_async)
      described_class.enqueue_worker
    end
  end
end
