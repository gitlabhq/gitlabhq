# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::MigrateRecordsToGhostUserInBatchesService do
  let(:service) { described_class.new }

  let_it_be(:ghost_user_migration) { create(:ghost_user_migration) }

  describe '#execute' do
    it 'stops when execution time limit reached' do
      expect_next_instance_of(::Gitlab::Utils::ExecutionTracker) do |tracker|
        expect(tracker).to receive(:over_limit?).and_return(true)
      end

      expect(Users::MigrateRecordsToGhostUserService).not_to receive(:new)

      service.execute
    end

    it 'calls Users::MigrateRecordsToGhostUserService' do
      expect_next_instance_of(Users::MigrateRecordsToGhostUserService) do |service|
        expect(service).to(
          receive(:execute)
            .with(hard_delete: ghost_user_migration.hard_delete))
      end

      service.execute
    end
  end
end
