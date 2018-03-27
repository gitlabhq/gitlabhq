require 'spec_helper'

describe Projects::HashedStorage::MigrateRepositoryService do
  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:project) { create(:project, :legacy_storage, :repository, :wiki_repo) }
  let(:service) { described_class.new(project) }
  let(:legacy_storage) { Storage::LegacyProject.new(project) }
  let(:hashed_storage) { Storage::HashedProject.new(project) }

  describe '#execute' do
    before do
      allow(service).to receive(:gitlab_shell) { gitlab_shell }
    end

    context 'when succeeds' do
      it 'renames project and wiki repositories' do
        service.execute

        expect(gitlab_shell.exists?(project.repository_storage_path, "#{hashed_storage.disk_path}.git")).to be_truthy
        expect(gitlab_shell.exists?(project.repository_storage_path, "#{hashed_storage.disk_path}.wiki.git")).to be_truthy
      end

      it 'updates project to be hashed and not read-only' do
        service.execute

        expect(project.hashed_storage?(:repository)).to be_truthy
        expect(project.repository_read_only).to be_falsey
      end

      it 'move operation is called for both repositories' do
        expect_move_repository(project.disk_path, hashed_storage.disk_path)
        expect_move_repository("#{project.disk_path}.wiki", "#{hashed_storage.disk_path}.wiki")

        service.execute
      end

      it 'writes project full path to .git/config' do
        service.execute

        expect(project.repository.rugged.config['gitlab.fullpath']).to eq project.full_path
      end
    end

    context 'when one move fails' do
      it 'rollsback repositories to original name' do
        from_name = project.disk_path
        to_name = hashed_storage.disk_path
        allow(service).to receive(:move_repository).and_call_original
        allow(service).to receive(:move_repository).with(from_name, to_name).once { false } # will disable first move only

        expect(service).to receive(:rollback_folder_move).and_call_original

        service.execute

        expect(gitlab_shell.exists?(project.repository_storage_path, "#{hashed_storage.disk_path}.git")).to be_falsey
        expect(gitlab_shell.exists?(project.repository_storage_path, "#{hashed_storage.disk_path}.wiki.git")).to be_falsey
        expect(project.repository_read_only?).to be_falsey
      end

      context 'when rollback fails' do
        let(:from_name) { legacy_storage.disk_path }
        let(:to_name) { hashed_storage.disk_path }

        before do
          hashed_storage.ensure_storage_path_exists
          gitlab_shell.mv_repository(project.repository_storage_path, from_name, to_name)
        end

        it 'does not try to move nil repository over hashed' do
          expect(gitlab_shell).not_to receive(:mv_repository).with(project.repository_storage_path, from_name, to_name)
          expect_move_repository("#{project.disk_path}.wiki", "#{hashed_storage.disk_path}.wiki")

          service.execute
        end
      end
    end

    def expect_move_repository(from_name, to_name)
      expect(gitlab_shell).to receive(:mv_repository).with(project.repository_storage_path, from_name, to_name).and_call_original
    end
  end
end
