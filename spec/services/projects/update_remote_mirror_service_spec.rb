require 'spec_helper'

describe Projects::UpdateRemoteMirrorService do
  let(:project) { create(:project) }
  let(:remote_project) { create(:forked_project_with_submodules) }
  let(:repository) { project.repository }
  let(:remote_repository) { remote_project.repository }
  let(:remote_mirror) { project.remote_mirrors.create!(url: remote_project.http_url_to_repo) }
  let(:all_branches) { ["master", 'existing-branch', "'test'", "empty-branch", "feature", "feature_conflict", "fix", "flatten-dir", "improve/awesome", "lfs", "markdown"] }

  subject { described_class.new(project, project.creator) }

  describe "#execute" do
    before do
      create_branch(repository, 'existing-branch')
    end

    it "fetches the remote repository" do
      expect(repository).to receive(:fetch_remote).with(remote_mirror.ref_name)

      subject.execute(remote_mirror)
    end

    it "succeeds" do
      allow(repository).to receive(:fetch_remote) { sync_remote(repository, remote_mirror.ref_name, all_branches) }

      result = subject.execute(remote_mirror)

      expect(result[:status]).to eq(:success)
    end

    describe 'Updating branches' do
      it "push all the branches the first time" do
        allow(repository).to receive(:fetch_remote)

        expect(repository).to receive(:push_branches).with(project.path_with_namespace, remote_mirror.ref_name, all_branches)

        subject.execute(remote_mirror)
      end

      it "does not push anything is remote is up to date" do
        allow(repository).to receive(:fetch_remote) { sync_remote(repository, remote_mirror.ref_name, all_branches) }

        expect(repository).not_to receive(:push_branches)

        subject.execute(remote_mirror)
      end

      it "sync new branches" do
        allow(repository).to receive(:fetch_remote) { sync_remote(repository, remote_mirror.ref_name, all_branches) }
        create_branch(repository, 'my-new-branch')

        expect(repository).to receive(:push_branches).with(project.path_with_namespace, remote_mirror.ref_name, ['my-new-branch'])

        subject.execute(remote_mirror)
      end

      it "sync updated branches" do
        allow(repository).to receive(:fetch_remote) do
          sync_remote(repository, remote_mirror.ref_name, all_branches)
          update_branch(repository, 'existing-branch')
        end

        expect(repository).to receive(:push_branches).with(project.path_with_namespace, remote_mirror.ref_name, ['existing-branch'])

        subject.execute(remote_mirror)
      end

      it "sync deleted branches" do
        allow(repository).to receive(:fetch_remote) do
          sync_remote(repository, remote_mirror.ref_name, all_branches)
          delete_branch(repository, 'existing-branch')
        end

        expect(repository).to receive(:delete_remote_branches).with(project.path_with_namespace, remote_mirror.ref_name, ['existing-branch'])

        subject.execute(remote_mirror)
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

  def sync_remote(repository, remote_name, all_branches)
    rugged = repository.rugged

    all_branches.each do |branch|
      target = repository.find_branch(branch).try(:target)
      rugged.references.create("refs/remotes/#{remote_name}/#{branch}", target) if target
    end
  end

  def update_branch(repository, branch)
    rugged = repository.rugged
    masterrev = repository.find_branch('master').target

    # # Updated existing branch
    rugged.references.create("refs/heads/#{branch}", masterrev, force: true)
    repository.expire_branches_cache
  end

  def delete_branch(repository, branch)
    rugged = repository.rugged

    rugged.references.delete("refs/heads/#{branch}")
    repository.expire_branches_cache
  end
end
