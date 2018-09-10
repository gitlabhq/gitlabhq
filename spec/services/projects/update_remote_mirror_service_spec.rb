require 'spec_helper'

describe Projects::UpdateRemoteMirrorService do
  let(:project) { create(:project, :repository) }
  let(:remote_project) { create(:forked_project_with_submodules) }
  let(:remote_mirror) { project.remote_mirrors.create!(url: remote_project.http_url_to_repo, enabled: true, only_protected_branches: false) }
  let(:remote_name) { remote_mirror.remote_name }

  subject(:service) { described_class.new(project, project.creator) }

  describe "#execute" do
    before do
      project.repository.add_branch(project.owner, 'existing-branch', 'master')

      allow(remote_mirror).to receive(:update_repository).and_return(true)
    end

    it "ensures the remote exists" do
      stub_fetch_remote(project, remote_name: remote_name)
      stub_find_remote_root_ref(project, remote_name: remote_name)

      expect(remote_mirror).to receive(:ensure_remote!)

      service.execute(remote_mirror)
    end

    it "fetches the remote repository" do
      stub_find_remote_root_ref(project, remote_name: remote_name)

      expect(project.repository)
        .to receive(:fetch_remote)
        .with(remote_mirror.remote_name, no_tags: true)

      service.execute(remote_mirror)
    end

    it "updates the default branch when HEAD has changed" do
      stub_fetch_remote(project, remote_name: remote_name)
      stub_find_remote_root_ref(project, remote_name: remote_name, ref: "existing-branch")

      expect { service.execute(remote_mirror) }
        .to change { project.default_branch }
        .from("master")
        .to("existing-branch")
    end

    it "does not update the default branch when HEAD does not change" do
      stub_fetch_remote(project, remote_name: remote_name)
      stub_find_remote_root_ref(project, remote_name: remote_name, ref: "master")

      expect { service.execute(remote_mirror) }.not_to change { project.default_branch }
    end

    it "returns success when updated succeeds" do
      stub_fetch_remote(project, remote_name: remote_name)
      stub_find_remote_root_ref(project, remote_name: remote_name)

      result = service.execute(remote_mirror)

      expect(result[:status]).to eq(:success)
    end

    context 'when syncing all branches' do
      it "push all the branches the first time" do
        stub_fetch_remote(project, remote_name: remote_name)
        stub_find_remote_root_ref(project, remote_name: remote_name)

        expect(remote_mirror).to receive(:update_repository).with({})

        service.execute(remote_mirror)
      end
    end

    context 'when only syncing protected branches' do
      it "sync updated protected branches" do
        stub_fetch_remote(project, remote_name: remote_name)
        stub_find_remote_root_ref(project, remote_name: remote_name)
        protected_branch = create_protected_branch(project)
        remote_mirror.only_protected_branches = true

        expect(remote_mirror)
          .to receive(:update_repository)
          .with(only_branches_matching: [protected_branch.name])

        service.execute(remote_mirror)
      end

      def create_protected_branch(project)
        branch_name = project.repository.branch_names.find { |n| n != 'existing-branch' }
        create(:protected_branch, project: project, name: branch_name)
      end
    end
  end

  def stub_find_remote_root_ref(project, ref: 'master', remote_name:)
    allow(project.repository)
      .to receive(:find_remote_root_ref)
      .with(remote_name)
      .and_return(ref)
  end

  def stub_fetch_remote(project, remote_name:)
    allow(project.repository)
      .to receive(:fetch_remote)
      .with(remote_name, no_tags: true) { fetch_remote(project.repository, remote_name) }
  end

  def fetch_remote(repository, remote_name)
    local_branch_names(repository).each do |branch|
      commit = repository.commit(branch)
      repository.write_ref("refs/remotes/#{remote_name}/#{branch}", commit.id) if commit
    end
  end

  def local_branch_names(repository)
    branch_names = repository.branches.map(&:name)
    # we want the protected branch to be pushed first
    branch_names.unshift(branch_names.delete('master'))
  end
end
