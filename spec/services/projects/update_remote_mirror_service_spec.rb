# frozen_string_literal: true

require 'spec_helper'

describe Projects::UpdateRemoteMirrorService do
  let(:project) { create(:project, :repository) }
  let(:remote_project) { create(:forked_project_with_submodules) }
  let(:remote_mirror) { project.remote_mirrors.create!(url: remote_project.http_url_to_repo, enabled: true, only_protected_branches: false) }
  let(:remote_name) { remote_mirror.remote_name }

  subject(:service) { described_class.new(project, project.creator) }

  describe '#execute' do
    subject(:execute!) { service.execute(remote_mirror, 0) }

    before do
      project.repository.add_branch(project.owner, 'existing-branch', 'master')

      allow(remote_mirror).to receive(:update_repository).and_return(true)
    end

    it 'ensures the remote exists' do
      stub_fetch_remote(project, remote_name: remote_name, ssh_auth: remote_mirror)

      expect(remote_mirror).to receive(:ensure_remote!)

      execute!
    end

    it 'fetches the remote repository' do
      expect(project.repository)
        .to receive(:fetch_remote)
              .with(remote_mirror.remote_name, no_tags: true, ssh_auth: remote_mirror)

      execute!
    end

    it 'marks the mirror as started when beginning' do
      expect(remote_mirror).to receive(:update_start!).and_call_original

      execute!
    end

    it 'marks the mirror as successfully finished' do
      stub_fetch_remote(project, remote_name: remote_name, ssh_auth: remote_mirror)

      result = execute!

      expect(result[:status]).to eq(:success)
      expect(remote_mirror).to be_finished
    end

    it 'marks the mirror as failed and raises the error when an unexpected error occurs' do
      allow(project.repository).to receive(:fetch_remote).and_raise('Badly broken')

      expect { execute! }.to raise_error /Badly broken/

      expect(remote_mirror).to be_failed
      expect(remote_mirror.last_error).to include('Badly broken')
    end

    context 'when the update fails because of a `Gitlab::Git::CommandError`' do
      before do
        allow(project.repository).to receive(:fetch_remote).and_raise(Gitlab::Git::CommandError.new('fetch failed'))
      end

      it 'wraps `Gitlab::Git::CommandError`s in a service error' do
        expect(execute!).to eq(status: :error, message: 'fetch failed')
      end

      it 'marks the mirror as to be retried' do
        execute!

        expect(remote_mirror).to be_to_retry
        expect(remote_mirror.last_error).to include('fetch failed')
      end

      it "marks the mirror as failed after #{described_class::MAX_TRIES} tries" do
        service.execute(remote_mirror, described_class::MAX_TRIES)

        expect(remote_mirror).to be_failed
        expect(remote_mirror.last_error).to include('fetch failed')
      end
    end

    context 'when syncing all branches' do
      it 'push all the branches the first time' do
        stub_fetch_remote(project, remote_name: remote_name, ssh_auth: remote_mirror)

        expect(remote_mirror).to receive(:update_repository).with({})

        execute!
      end
    end

    context 'when only syncing protected branches' do
      it 'sync updated protected branches' do
        stub_fetch_remote(project, remote_name: remote_name, ssh_auth: remote_mirror)
        protected_branch = create_protected_branch(project)
        remote_mirror.only_protected_branches = true

        expect(remote_mirror)
          .to receive(:update_repository)
          .with(only_branches_matching: [protected_branch.name])

        execute!
      end

      def create_protected_branch(project)
        branch_name = project.repository.branch_names.find { |n| n != 'existing-branch' }
        create(:protected_branch, project: project, name: branch_name)
      end
    end
  end

  def stub_fetch_remote(project, remote_name:, ssh_auth:)
    allow(project.repository)
      .to receive(:fetch_remote)
      .with(remote_name, no_tags: true, ssh_auth: ssh_auth) { fetch_remote(project.repository, remote_name) }
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
