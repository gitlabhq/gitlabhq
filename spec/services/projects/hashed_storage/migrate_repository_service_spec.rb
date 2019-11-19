# frozen_string_literal: true

require 'spec_helper'

describe Projects::HashedStorage::MigrateRepositoryService do
  include GitHelpers

  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:project) { create(:project, :legacy_storage, :repository, :wiki_repo) }
  let(:legacy_storage) { Storage::LegacyProject.new(project) }
  let(:hashed_storage) { Storage::HashedProject.new(project) }

  subject(:service) { described_class.new(project: project, old_disk_path: project.disk_path) }

  describe '#execute' do
    let(:old_disk_path) { legacy_storage.disk_path }
    let(:new_disk_path) { hashed_storage.disk_path }

    before do
      allow(service).to receive(:gitlab_shell) { gitlab_shell }
    end

    context 'repository lock' do
      it 'tries to lock the repository' do
        expect(service).to receive(:try_to_set_repository_read_only!)

        service.execute
      end

      it 'fails when a git operation is in progress' do
        allow(project).to receive(:repo_reference_count) { 1 }

        expect { service.execute }.to raise_error(Projects::HashedStorage::RepositoryInUseError)
      end
    end

    context 'when repository doesnt exist on disk' do
      let(:project) { create(:project, :legacy_storage) }

      it 'skips the disk change but increase the version' do
        service.execute

        expect(project.hashed_storage?(:repository)).to be_truthy
      end
    end

    context 'when succeeds' do
      it 'renames project and wiki repositories' do
        service.execute

        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{new_disk_path}.git")).to be_truthy
        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{new_disk_path}.wiki.git")).to be_truthy
      end

      it 'updates project to be hashed and not read-only' do
        service.execute

        expect(project.hashed_storage?(:repository)).to be_truthy
        expect(project.repository_read_only).to be_falsey
      end

      it 'move operation is called for both repositories' do
        expect_move_repository(old_disk_path, new_disk_path)
        expect_move_repository("#{old_disk_path}.wiki", "#{new_disk_path}.wiki")

        service.execute
      end

      it 'writes project full path to .git/config' do
        service.execute

        rugged_config = rugged_repo(project.repository).config['gitlab.fullpath']

        expect(rugged_config).to eq project.full_path
      end
    end

    context 'when one move fails' do
      it 'rollsback repositories to original name' do
        allow(service).to receive(:move_repository).and_call_original
        allow(service).to receive(:move_repository).with(old_disk_path, new_disk_path).once { false } # will disable first move only

        expect(service).to receive(:rollback_folder_move).and_call_original

        service.execute

        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{new_disk_path}.git")).to be_falsey
        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{new_disk_path}.wiki.git")).to be_falsey
        expect(project.repository_read_only?).to be_falsey
      end

      context 'when rollback fails' do
        before do
          gitlab_shell.mv_repository(project.repository_storage, old_disk_path, new_disk_path)
        end

        it 'does not try to move nil repository over existing' do
          expect(gitlab_shell).not_to receive(:mv_repository).with(project.repository_storage, old_disk_path, new_disk_path)
          expect_move_repository("#{old_disk_path}.wiki", "#{new_disk_path}.wiki")

          service.execute
        end
      end
    end

    it 'works even when project validation fails' do
      allow(project).to receive(:valid?) { false }

      expect { service.execute }.to change { project.hashed_storage?(:repository) }.to(true)
    end

    def expect_move_repository(from_name, to_name)
      expect(gitlab_shell).to receive(:mv_repository).with(project.repository_storage, from_name, to_name).and_call_original
    end
  end
end
