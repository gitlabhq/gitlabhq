# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupProjectPipelineStatusKey, feature_category: :redis do
  it 'enqueues a RedisMigrationWorker job from cursor 0' do
    expect(RedisMigrationWorker).to receive(:perform_async).with('BackfillProjectPipelineStatusTtl', '0')

    migrate!
  end
end
