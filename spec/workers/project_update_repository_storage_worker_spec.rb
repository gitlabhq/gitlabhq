# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectUpdateRepositoryStorageWorker do
  let(:project) { create(:project, :repository) }

  subject { described_class.new }

  describe "#perform" do
    let(:service) { double(:update_repository_storage_service) }

    before do
      allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(%w[default test_second_storage])
    end

    context 'without repository storage move' do
      it "calls the update repository storage service" do
        expect(Projects::UpdateRepositoryStorageService).to receive(:new).and_return(service)
        expect(service).to receive(:execute)

        expect do
          subject.perform(project.id, 'test_second_storage')
        end.to change(ProjectRepositoryStorageMove, :count).by(1)

        storage_move = project.repository_storage_moves.last
        expect(storage_move).to have_attributes(
          source_storage_name: "default",
          destination_storage_name: "test_second_storage"
        )
      end
    end

    context 'with repository storage move' do
      let!(:repository_storage_move) { create(:project_repository_storage_move) }

      it "calls the update repository storage service" do
        expect(Projects::UpdateRepositoryStorageService).to receive(:new).and_return(service)
        expect(service).to receive(:execute)

        expect do
          subject.perform(nil, nil, repository_storage_move.id)
        end.not_to change(ProjectRepositoryStorageMove, :count)
      end
    end
  end
end
