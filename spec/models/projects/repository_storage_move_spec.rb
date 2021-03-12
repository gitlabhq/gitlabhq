# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RepositoryStorageMove, type: :model do
  let_it_be_with_refind(:project) { create(:project) }

  it_behaves_like 'handles repository moves' do
    let(:container) { project }
    let(:repository_storage_factory_key) { :project_repository_storage_move }
    let(:error_key) { :project }
    let(:repository_storage_worker) { Projects::UpdateRepositoryStorageWorker }
  end

  describe 'state transitions' do
    let(:storage) { 'test_second_storage' }

    before do
      stub_storage_settings(storage => { 'path' => 'tmp/tests/extra_storage' })
    end

    context 'when started' do
      subject(:storage_move) { create(:project_repository_storage_move, :started, container: project, destination_storage_name: storage) }

      context 'and transits to replicated' do
        it 'sets the repository storage and marks the container as writable' do
          storage_move.finish_replication!

          expect(project.repository_storage).to eq(storage)
          expect(project).not_to be_repository_read_only
        end
      end
    end
  end
end
