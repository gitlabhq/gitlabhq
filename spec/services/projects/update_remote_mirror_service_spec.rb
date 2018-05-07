require 'spec_helper'

describe Projects::UpdateRemoteMirrorService do
  let(:project) { create(:project, :repository) }
  let(:remote_project) { create(:forked_project_with_submodules) }
  let(:repository) { project.repository }
  let(:raw_repository) { repository.raw }
  let(:remote_mirror) { project.remote_mirrors.create!(url: remote_project.http_url_to_repo, enabled: true, only_protected_branches: false) }

  subject { described_class.new(project, project.creator) }

  describe "#execute", :skip_gitaly_mock do
    before do
      create_branch(repository, 'existing-branch')
      allow(raw_repository).to receive(:remote_tags) do
        generate_tags(repository, 'v1.0.0', 'v1.1.0')
      end
      allow(raw_repository).to receive(:push_remote_branches).and_return(true)
    end

    it "fetches the remote repository" do
      expect(repository).to receive(:fetch_remote).with(remote_mirror.remote_name, no_tags: true) do
        sync_remote(repository, remote_mirror.remote_name, local_branch_names)
      end

      subject.execute(remote_mirror)
    end

    it "succeeds" do
      allow(repository).to receive(:fetch_remote) { sync_remote(repository, remote_mirror.remote_name, local_branch_names) }

      result = subject.execute(remote_mirror)

      expect(result[:status]).to eq(:success)
    end

    describe 'Syncing branches' do
      it "push all the branches the first time" do
        allow(repository).to receive(:fetch_remote)

        expect(raw_repository).to receive(:push_remote_branches).with(remote_mirror.remote_name, local_branch_names)

        subject.execute(remote_mirror)
      end

      it "does not push anything is remote is up to date" do
        allow(repository).to receive(:fetch_remote) { sync_remote(repository, remote_mirror.remote_name, local_branch_names) }

        expect(raw_repository).not_to receive(:push_remote_branches)

        subject.execute(remote_mirror)
      end

      it "sync new branches" do
        # call local_branch_names early so it is not called after the new branch has been created
        current_branches = local_branch_names
        allow(repository).to receive(:fetch_remote) { sync_remote(repository, remote_mirror.remote_name, current_branches) }
        create_branch(repository, 'my-new-branch')

        expect(raw_repository).to receive(:push_remote_branches).with(remote_mirror.remote_name, ['my-new-branch'])

        subject.execute(remote_mirror)
      end

      it "sync updated branches" do
        allow(repository).to receive(:fetch_remote) do
          sync_remote(repository, remote_mirror.remote_name, local_branch_names)
          update_branch(repository, 'existing-branch')
        end

        expect(raw_repository).to receive(:push_remote_branches).with(remote_mirror.remote_name, ['existing-branch'])

        subject.execute(remote_mirror)
      end

      context 'when push only protected branches option is set' do
        let(:unprotected_branch_name) { 'existing-branch' }
        let(:protected_branch_name) do
          project.repository.branch_names.find { |n| n != unprotected_branch_name }
        end
        let!(:protected_branch) do
          create(:protected_branch, project: project, name: protected_branch_name)
        end

        before do
          project.reload
          remote_mirror.only_protected_branches = true
        end

        it "sync updated protected branches" do
          allow(repository).to receive(:fetch_remote) do
            sync_remote(repository, remote_mirror.remote_name, local_branch_names)
            update_branch(repository, protected_branch_name)
          end

          expect(raw_repository).to receive(:push_remote_branches).with(remote_mirror.remote_name, [protected_branch_name])

          subject.execute(remote_mirror)
        end

        it 'does not sync unprotected branches' do
          allow(repository).to receive(:fetch_remote) do
            sync_remote(repository, remote_mirror.remote_name, local_branch_names)
            update_branch(repository, unprotected_branch_name)
          end

          expect(raw_repository).not_to receive(:push_remote_branches).with(remote_mirror.remote_name, [unprotected_branch_name])

          subject.execute(remote_mirror)
        end
      end

      context 'when branch exists in local and remote repo' do
        context 'when it has diverged' do
          it 'syncs branches' do
            allow(repository).to receive(:fetch_remote) do
              sync_remote(repository, remote_mirror.remote_name, local_branch_names)
              update_remote_branch(repository, remote_mirror.remote_name, 'markdown')
            end

            expect(raw_repository).to receive(:push_remote_branches).with(remote_mirror.remote_name, ['markdown'])

            subject.execute(remote_mirror)
          end
        end
      end

      describe 'for delete' do
        context 'when branch exists in local and remote repo' do
          it 'deletes the branch from remote repo' do
            allow(repository).to receive(:fetch_remote) do
              sync_remote(repository, remote_mirror.remote_name, local_branch_names)
              delete_branch(repository, 'existing-branch')
            end

            expect(raw_repository).to receive(:delete_remote_branches).with(remote_mirror.remote_name, ['existing-branch'])

            subject.execute(remote_mirror)
          end
        end

        context 'when push only protected branches option is set' do
          before do
            remote_mirror.only_protected_branches = true
          end

          context 'when branch exists in local and remote repo' do
            let!(:protected_branch_name) { local_branch_names.first }

            before do
              create(:protected_branch, project: project, name: protected_branch_name)
              project.reload
            end

            it 'deletes the protected branch from remote repo' do
              allow(repository).to receive(:fetch_remote) do
                sync_remote(repository, remote_mirror.remote_name, local_branch_names)
                delete_branch(repository, protected_branch_name)
              end

              expect(raw_repository).not_to receive(:delete_remote_branches).with(remote_mirror.remote_name, [protected_branch_name])

              subject.execute(remote_mirror)
            end

            it 'does not delete the unprotected branch from remote repo' do
              allow(repository).to receive(:fetch_remote) do
                sync_remote(repository, remote_mirror.remote_name, local_branch_names)
                delete_branch(repository, 'existing-branch')
              end

              expect(raw_repository).not_to receive(:delete_remote_branches).with(remote_mirror.remote_name, ['existing-branch'])

              subject.execute(remote_mirror)
            end
          end

          context 'when branch only exists on remote repo' do
            let!(:protected_branch_name) { 'remote-branch' }

            before do
              create(:protected_branch, project: project, name: protected_branch_name)
            end

            context 'when it has diverged' do
              it 'does not delete the remote branch' do
                allow(repository).to receive(:fetch_remote) do
                  sync_remote(repository, remote_mirror.remote_name, local_branch_names)

                  rev = repository.find_branch('markdown').dereferenced_target
                  create_remote_branch(repository, remote_mirror.remote_name, 'remote-branch', rev.id)
                end

                expect(raw_repository).not_to receive(:delete_remote_branches)

                subject.execute(remote_mirror)
              end
            end

            context 'when it has not diverged' do
              it 'deletes the remote branch' do
                allow(repository).to receive(:fetch_remote) do
                  sync_remote(repository, remote_mirror.remote_name, local_branch_names)

                  masterrev = repository.find_branch('master').dereferenced_target
                  create_remote_branch(repository, remote_mirror.remote_name, protected_branch_name, masterrev.id)
                end

                expect(raw_repository).to receive(:delete_remote_branches).with(remote_mirror.remote_name, [protected_branch_name])

                subject.execute(remote_mirror)
              end
            end
          end
        end

        context 'when branch only exists on remote repo' do
          context 'when it has diverged' do
            it 'does not delete the remote branch' do
              allow(repository).to receive(:fetch_remote) do
                sync_remote(repository, remote_mirror.remote_name, local_branch_names)

                rev = repository.find_branch('markdown').dereferenced_target
                create_remote_branch(repository, remote_mirror.remote_name, 'remote-branch', rev.id)
              end

              expect(raw_repository).not_to receive(:delete_remote_branches)

              subject.execute(remote_mirror)
            end
          end

          context 'when it has not diverged' do
            it 'deletes the remote branch' do
              allow(repository).to receive(:fetch_remote) do
                sync_remote(repository, remote_mirror.remote_name, local_branch_names)

                masterrev = repository.find_branch('master').dereferenced_target
                create_remote_branch(repository, remote_mirror.remote_name, 'remote-branch', masterrev.id)
              end

              expect(raw_repository).to receive(:delete_remote_branches).with(remote_mirror.remote_name, ['remote-branch'])

              subject.execute(remote_mirror)
            end
          end
        end
      end
    end

    describe 'Syncing tags' do
      before do
        allow(repository).to receive(:fetch_remote) { sync_remote(repository, remote_mirror.remote_name, local_branch_names) }
      end

      context 'when there are not tags to push' do
        it 'does not try to push tags' do
          allow(repository).to receive(:remote_tags) { {} }
          allow(repository).to receive(:tags) { [] }

          expect(repository).not_to receive(:push_tags)

          subject.execute(remote_mirror)
        end
      end

      context 'when there are some tags to push' do
        it 'pushes tags to remote' do
          allow(raw_repository).to receive(:remote_tags) { {} }

          expect(raw_repository).to receive(:push_remote_branches).with(remote_mirror.remote_name, ['v1.0.0', 'v1.1.0'])

          subject.execute(remote_mirror)
        end
      end

      context 'when there are some tags to delete' do
        it 'deletes tags from remote' do
          remote_tags = generate_tags(repository, 'v1.0.0', 'v1.1.0')
          allow(raw_repository).to receive(:remote_tags) { remote_tags }

          repository.rm_tag(create(:user), 'v1.0.0')

          expect(raw_repository).to receive(:delete_remote_branches).with(remote_mirror.remote_name, ['v1.0.0'])

          subject.execute(remote_mirror)
        end
      end
    end
  end

  def create_branch(repository, branch_name)
    rugged = repository.rugged
    masterrev = repository.find_branch('master').dereferenced_target
    parentrev = repository.commit(masterrev).parent_id

    rugged.references.create("refs/heads/#{branch_name}", parentrev)

    repository.expire_branches_cache
  end

  def create_remote_branch(repository, remote_name, branch_name, source_id)
    rugged = repository.rugged

    rugged.references.create("refs/remotes/#{remote_name}/#{branch_name}", source_id)
  end

  def sync_remote(repository, remote_name, local_branch_names)
    rugged = repository.rugged

    local_branch_names.each do |branch|
      target = repository.find_branch(branch).try(:dereferenced_target)
      rugged.references.create("refs/remotes/#{remote_name}/#{branch}", target.id) if target
    end
  end

  def update_remote_branch(repository, remote_name, branch)
    rugged = repository.rugged
    masterrev = repository.find_branch('master').dereferenced_target.id

    rugged.references.create("refs/remotes/#{remote_name}/#{branch}", masterrev, force: true)
    repository.expire_branches_cache
  end

  def update_branch(repository, branch)
    rugged = repository.rugged
    masterrev = repository.find_branch('master').dereferenced_target.id

    # Updated existing branch
    rugged.references.create("refs/heads/#{branch}", masterrev, force: true)
    repository.expire_branches_cache
  end

  def delete_branch(repository, branch)
    rugged = repository.rugged

    rugged.references.delete("refs/heads/#{branch}")
    repository.expire_branches_cache
  end

  def generate_tags(repository, *tag_names)
    tag_names.each_with_object([]) do |name, tags|
      tag = repository.find_tag(name)
      target = tag.try(:target)
      target_commit = tag.try(:dereferenced_target)
      tags << Gitlab::Git::Tag.new(repository.raw_repository, name, target, target_commit)
    end
  end

  def local_branch_names
    branch_names = repository.branches.map(&:name)
    # we want the protected branch to be pushed first
    branch_names.unshift(branch_names.delete('master'))
  end
end
