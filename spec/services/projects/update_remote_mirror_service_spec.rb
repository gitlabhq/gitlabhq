require 'spec_helper'

describe Projects::UpdateRemoteMirrorService do
  let(:project) { create(:project) }
  let(:remote_project) { create(:forked_project_with_submodules) }
  let(:repository) { project.repository }
  let(:remote_mirror) { project.remote_mirrors.create!(url: remote_project.http_url_to_repo) }

  subject { described_class.new(project, project.creator) }

  describe "#execute" do
    before do
      create_branch(repository, 'existing-branch')
      allow(repository).to receive(:remote_tags) { generate_tags(repository, 'v1.0.0', 'v1.1.0') }
    end

    it "fetches the remote repository" do
      expect(repository).to receive(:fetch_remote).with(remote_mirror.ref_name, no_tags: true) do
        sync_remote(repository, remote_mirror.ref_name, local_branch_names)
      end

      subject.execute(remote_mirror)
    end

    it "succeeds" do
      allow(repository).to receive(:fetch_remote) { sync_remote(repository, remote_mirror.ref_name, local_branch_names) }

      result = subject.execute(remote_mirror)

      expect(result[:status]).to eq(:success)
    end

    describe 'Syncing branches' do
      it "push all the branches the first time" do
        allow(repository).to receive(:fetch_remote)

        expect(repository).to receive(:push_remote_branches).with(remote_mirror.ref_name, local_branch_names)

        subject.execute(remote_mirror)
      end

      it "does not push anything is remote is up to date" do
        allow(repository).to receive(:fetch_remote) { sync_remote(repository, remote_mirror.ref_name, local_branch_names) }

        expect(repository).not_to receive(:push_remote_branches)

        subject.execute(remote_mirror)
      end

      it "sync new branches" do
        # call local_branch_names early so it is not called after the new branch has been created
        current_branches = local_branch_names
        allow(repository).to receive(:fetch_remote) { sync_remote(repository, remote_mirror.ref_name, current_branches) }
        create_branch(repository, 'my-new-branch')

        expect(repository).to receive(:push_remote_branches).with(remote_mirror.ref_name, ['my-new-branch'])

        subject.execute(remote_mirror)
      end

      it "sync updated branches" do
        allow(repository).to receive(:fetch_remote) do
          sync_remote(repository, remote_mirror.ref_name, local_branch_names)
          update_branch(repository, 'existing-branch')
        end

        expect(repository).to receive(:push_remote_branches).with(remote_mirror.ref_name, ['existing-branch'])

        subject.execute(remote_mirror)
      end

      it "sync deleted branches" do
        allow(repository).to receive(:fetch_remote) do
          sync_remote(repository, remote_mirror.ref_name, local_branch_names)
          delete_branch(repository, 'existing-branch')
        end

        expect(repository).to receive(:delete_remote_branches).with(remote_mirror.ref_name, ['existing-branch'])

        subject.execute(remote_mirror)
      end
    end

    describe 'Syncing tags' do
      before do
        allow(repository).to receive(:fetch_remote) { sync_remote(repository, remote_mirror.ref_name, local_branch_names) }
      end

      context 'when there are not tags to push' do
        it 'should not try to push tags' do
          allow(repository).to receive(:remote_tags) { {} }
          allow(repository).to receive(:tags) { [] }

          expect(repository).not_to receive(:push_tags)

          subject.execute(remote_mirror)
        end
      end

      context 'when there are some tags to push' do
        it 'should push tags to remote' do
          allow(repository).to receive(:remote_tags) { {} }

          expect(repository).to receive(:push_remote_branches).with(remote_mirror.ref_name, ['v1.0.0', 'v1.1.0'])

          subject.execute(remote_mirror)
        end
      end

      context 'when there are some tags to delete' do
        it 'should delete tags from remote' do
          allow(repository).to receive(:remote_tags) { generate_tags(repository, 'v1.0.0', 'v1.1.0') }
          repository.rm_tag('v1.0.0')

          expect(repository).to receive(:delete_remote_branches).with(remote_mirror.ref_name, ['v1.0.0'])

          subject.execute(remote_mirror)
        end
      end
    end

  end

  def create_branch(repository, branch_name)
    rugged = repository.rugged
    masterrev = repository.find_branch('master').target
    parentrev = repository.commit(masterrev).parent_id

    rugged.references.create("refs/heads/#{branch_name}", parentrev)

    repository.expire_branches_cache
  end

  def sync_remote(repository, remote_name, local_branch_names)
    rugged = repository.rugged

    local_branch_names.each do |branch|
      target = repository.find_branch(branch).try(:target)
      rugged.references.create("refs/remotes/#{remote_name}/#{branch}", target) if target
    end
  end

  def update_branch(repository, branch)
    rugged = repository.rugged
    masterrev = repository.find_branch('master').target

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
      tag_rev = repository.find_tag(name).try(:target)
      tags << Gitlab::Git::Tag.new(name, tag_rev)
    end
  end

  def local_branch_names
    branch_names = repository.branches.map(&:name)
    # we want the protected branch to be pushed first
    branch_names.unshift(branch_names.delete('master'))
  end
end
