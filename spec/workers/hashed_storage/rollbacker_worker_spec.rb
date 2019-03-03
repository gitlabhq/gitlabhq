# frozen_string_literal: true

require 'spec_helper'

describe HashedStorage::RollbackerWorker do
  subject(:worker) { described_class.new }
  let(:projects) { create_list(:project, 2, :empty_repo) }
  let(:ids) { projects.map(&:id) }

  describe '#perform' do
    it 'delegates to MigratorService' do
      expect_any_instance_of(Gitlab::HashedStorage::Migrator).to receive(:bulk_rollback).with(start: 5, finish: 10)

      worker.perform(5, 10)
    end

    it 'rollsback projects in the specified range' do
      perform_enqueued_jobs do
        worker.perform(ids.min, ids.max)
      end

      projects.each do |project|
        expect(project.reload.legacy_storage?).to be_truthy
      end
    end
  end
end
