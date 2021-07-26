# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UpdateRemoteMirrorService do
  let_it_be(:project) { create(:project, :repository, lfs_enabled: true) }
  let_it_be(:remote_project) { create(:forked_project_with_submodules) }
  let_it_be(:remote_mirror) { create(:remote_mirror, project: project, enabled: true) }

  let(:remote_name) { remote_mirror.remote_name }

  subject(:service) { described_class.new(project, project.creator) }

  describe '#execute' do
    let(:retries) { 0 }

    subject(:execute!) { service.execute(remote_mirror, retries) }

    before do
      project.repository.add_branch(project.owner, 'existing-branch', 'master')

      allow(remote_mirror)
        .to receive(:update_repository)
        .and_return(double(divergent_refs: []))
    end

    it 'does not fetch the remote repository' do
      # See https://gitlab.com/gitlab-org/gitaly/-/issues/2670
      expect(project.repository).not_to receive(:fetch_remote)

      execute!
    end

    it 'marks the mirror as started when beginning' do
      expect(remote_mirror).to receive(:update_start!).and_call_original

      execute!
    end

    it 'marks the mirror as successfully finished' do
      result = execute!

      expect(result[:status]).to eq(:success)
      expect(remote_mirror).to be_finished
    end

    it 'marks the mirror as failed and raises the error when an unexpected error occurs' do
      allow(remote_mirror).to receive(:update_repository).and_raise('Badly broken')

      expect { execute! }.to raise_error(/Badly broken/)

      expect(remote_mirror).to be_failed
      expect(remote_mirror.last_error).to include('Badly broken')
    end

    context 'when the URL is blocked' do
      before do
        allow(Gitlab::UrlBlocker).to receive(:blocked_url?).and_return(true)
      end

      it 'hard retries and returns error status' do
        expect(execute!).to eq(status: :error, message: 'The remote mirror URL is invalid.')
        expect(remote_mirror).to be_to_retry
      end

      context 'when retries are exceeded' do
        let(:retries) { 4 }

        it 'hard fails and returns error status' do
          expect(execute!).to eq(status: :error, message: 'The remote mirror URL is invalid.')
          expect(remote_mirror).to be_failed
        end
      end
    end

    context "when given URLs containing escaped elements" do
      it_behaves_like "URLs containing escaped elements return expected status" do
        let(:result) { execute! }

        before do
          allow(remote_mirror).to receive(:url).and_return(url)
        end
      end
    end

    context 'when the update fails because of a `Gitlab::Git::CommandError`' do
      before do
        allow(remote_mirror).to receive(:update_repository)
          .and_raise(Gitlab::Git::CommandError.new('update failed'))
      end

      it 'wraps `Gitlab::Git::CommandError`s in a service error' do
        expect(execute!).to eq(status: :error, message: 'update failed')
      end

      it 'marks the mirror as to be retried' do
        execute!

        expect(remote_mirror).to be_to_retry
        expect(remote_mirror.last_error).to include('update failed')
      end

      it "marks the mirror as failed after #{described_class::MAX_TRIES} tries" do
        service.execute(remote_mirror, described_class::MAX_TRIES)

        expect(remote_mirror).to be_failed
        expect(remote_mirror.last_error).to include('update failed')
      end
    end

    context 'when there are divergent refs' do
      it 'marks the mirror as failed and sets an error message' do
        response = double(divergent_refs: %w[refs/heads/master refs/heads/develop])
        expect(remote_mirror).to receive(:update_repository).and_return(response)

        execute!

        expect(remote_mirror).to be_failed
        expect(remote_mirror.last_error).to include("Some refs have diverged")
        expect(remote_mirror.last_error).to include("refs/heads/master\n")
        expect(remote_mirror.last_error).to include("refs/heads/develop")
      end
    end

    context "sending lfs objects" do
      let_it_be(:lfs_pointer) { create(:lfs_objects_project, project: project) }

      before do
        stub_lfs_setting(enabled: true)
      end

      it 'pushes LFS objects to a HTTP repository' do
        expect_next_instance_of(Lfs::PushService) do |service|
          expect(service).to receive(:execute)
        end

        execute!
      end

      it 'does nothing to an SSH repository' do
        remote_mirror.update!(url: 'ssh://example.com')

        expect_any_instance_of(Lfs::PushService).not_to receive(:execute)

        execute!
      end

      it 'does nothing if LFS is disabled' do
        expect(project).to receive(:lfs_enabled?) { false }

        expect_any_instance_of(Lfs::PushService).not_to receive(:execute)

        execute!
      end

      it 'does nothing if non-password auth is specified' do
        remote_mirror.update!(auth_method: 'ssh_public_key')

        expect_any_instance_of(Lfs::PushService).not_to receive(:execute)

        execute!
      end
    end
  end
end
