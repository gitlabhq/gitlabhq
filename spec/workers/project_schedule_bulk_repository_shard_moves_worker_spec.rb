# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectScheduleBulkRepositoryShardMovesWorker do
  describe "#perform" do
    before do
      stub_storage_settings('test_second_storage' => { 'path' => 'tmp/tests/extra_storage' })

      allow(ProjectUpdateRepositoryStorageWorker).to receive(:perform_async)
    end

    let!(:project) { create(:project, :repository).tap { |project| project.track_project_repository } }
    let(:source_storage_name) { 'default' }
    let(:destination_storage_name) { 'test_second_storage' }

    include_examples 'an idempotent worker' do
      let(:job_args) { [source_storage_name, destination_storage_name] }

      it 'schedules project repository storage moves' do
        expect { subject }.to change(ProjectRepositoryStorageMove, :count).by(1)

        storage_move = project.repository_storage_moves.last!

        expect(storage_move).to have_attributes(
          source_storage_name: source_storage_name,
          destination_storage_name: destination_storage_name,
          state_name: :scheduled
        )
      end
    end
  end
end
