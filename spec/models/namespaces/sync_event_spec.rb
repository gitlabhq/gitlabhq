# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::SyncEvent, feature_category: :cell do
  it_behaves_like 'a database sync event table', :namespace

  describe '.enqueue_worker' do
    it 'schedules Namespaces::ProcessSyncEventsWorker job' do
      expect(::Namespaces::ProcessSyncEventsWorker).to receive(:perform_async)
      described_class.enqueue_worker
    end
  end
end
