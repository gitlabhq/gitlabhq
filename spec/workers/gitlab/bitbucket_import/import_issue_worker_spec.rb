# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::ImportIssueWorker, feature_category: :importers do
  subject(:worker) { described_class.new }

  describe '#perform' do
    it 'notifies the waiter without importing anything' do
      expect(Gitlab::JobWaiter).to receive(:notify).with('key', anything)

      worker.perform(1, { 'iid' => 1 }, 'key')
    end
  end
end
