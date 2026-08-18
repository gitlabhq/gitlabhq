# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::MigrateNonHumanRecordsToGhostUserInBatchesWorker, feature_category: :user_profile do
  include ExclusiveLeaseHelpers

  let(:worker) { described_class.new }

  describe '#perform', :clean_gitlab_redis_shared_state do
    it 'is no-op' do
      expect(Users::MigrateRecordsToGhostUserInBatchesService).not_to receive(:new)

      worker.perform
    end
  end
end
