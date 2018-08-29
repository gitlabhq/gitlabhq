require 'spec_helper'

describe Projects::UpdateRemoteMirrorService do
  set(:project) { create(:project, :repository) }
  let(:owner) { project.owner }
  let(:remote_project) { create(:forked_project_with_submodules) }
  let(:repository) { project.repository }
  let(:raw_repository) { repository.raw }
  let(:remote_mirror) { project.remote_mirrors.create!(url: remote_project.http_url_to_repo, enabled: true, only_protected_branches: false) }

  subject { described_class.new(project, project.creator) }

  describe "#execute" do
    before do
      repository.add_branch(owner, 'existing-branch', 'master')

      allow(remote_mirror).to receive(:update_repository).and_return(true)
    end

    it "fetches the remote repository" do
      expect(remote_mirror).to receive(:ensure_remote!).and_call_original
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

    context 'when syncing all branches' do
      it "push all the branches the first time" do
        allow(repository).to receive(:fetch_remote)

        expect(remote_mirror).to receive(:update_repository).with({})

        subject.execute(remote_mirror)
      end
    end

    context 'when only syncing protected branches' do
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
        allow(repository).to receive(:fetch_remote)
        expect(remote_mirror).to receive(:update_repository).with(only_branches_matching: [protected_branch_name])

        subject.execute(remote_mirror)
      end
    end
  end

  def sync_remote(repository, remote_name, local_branch_names)
    local_branch_names.each do |branch|
      commit = repository.commit(branch)
      repository.write_ref("refs/remotes/#{remote_name}/#{branch}", commit.id) if commit
    end
  end

  def update_remote_branch(repository, remote_name, branch)
    masterrev = repository.commit('master').id

    repository.write_ref("refs/remotes/#{remote_name}/#{branch}", masterrev, force: true)
    repository.expire_branches_cache
  end

  def update_branch(repository, branch)
    masterrev = repository.commit('master').id

    repository.write_ref("refs/heads/#{branch}", masterrev, force: true)
    repository.expire_branches_cache
  end

  def generate_tags(repository, *tag_names)
    tag_names.each_with_object([]) do |name, tags|
      tag = repository.find_tag(name)
      target = tag.try(:target)
      target_commit = tag.try(:dereferenced_target)
      tags << Gitlab::Git::Tag.new(repository.raw_repository, {
        name: name,
        target: target,
        target_commit: target_commit
      })
    end
  end

  def local_branch_names
    branch_names = repository.branches.map(&:name)
    # we want the protected branch to be pushed first
    branch_names.unshift(branch_names.delete('master'))
  end
end
