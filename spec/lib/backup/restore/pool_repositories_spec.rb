# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Restore::PoolRepositories, feature_category: :backup_restore do
  subject(:pools) { described_class }

  let(:result) { described_class::Result }

  describe '.reinitialize_pools!' do
    context 'with a pool without a source project' do
      let(:pool_repository) { create(:pool_repository, :without_project) }

      it 'yields a skipped result' do
        results = []
        expected = result.new(disk_path: pool_repository.disk_path, status: :skipped, error_message: nil)

        pools.reinitialize_pools! { |result| results << result }

        expect(results).to include(expected)
      end
    end

    context 'with a ready pool repository' do
      let(:pool_repository) { create(:pool_repository, :ready).tap(&:delete_object_pool) }

      it 'yields a scheduled result' do
        results = []
        expected = result.new(disk_path: pool_repository.disk_path, status: :scheduled, error_message: nil)

        pools.reinitialize_pools! { |result| results << result }

        expect(results).to include(expected)
      end
    end

    context 'when an exception is raised' do
      let(:pool_repository) { create(:pool_repository, :ready).tap(&:delete_object_pool) }

      it 'yields a failed result' do
        results = []
        expected = result.new(disk_path: pool_repository.disk_path, status: :failed, error_message: 'Some error')

        # rubocop:disable RSpec/AnyInstanceOf -- expect_next_instances_of doesn't work with find_each
        expect_any_instance_of(PoolRepository).to receive(:reinitialize).and_raise StandardError, 'Some error'
        # rubocop:enable RSpec/AnyInstanceOf

        pools.reinitialize_pools! { |result| results << result }

        expect(results).to include(expected)
      end
    end
  end
end
