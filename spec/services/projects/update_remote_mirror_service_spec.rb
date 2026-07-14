# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UpdateRemoteMirrorService, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :small_repo, lfs_enabled: true) }
  let_it_be(:remote_project) { create(:forked_project_with_submodules) }
  let_it_be_with_reload(:remote_mirror) { create(:remote_mirror, project: project, enabled: true) }

  subject(:service) { described_class.new(project, project.creator) }

  describe '#execute' do
    let(:retries) { 0 }

    subject(:execute!) { service.execute(remote_mirror, retries) }

    before do
      project.repository.add_branch(project.first_owner, 'existing-branch', 'master')

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
        allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
          .and_raise(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError, 'URL is blocked')
      end

      it 'hard retries and returns error status', :aggregate_failures do
        result = execute!

        expect(result).to eq(status: :error, message: 'The remote mirror URL is invalid: URL is blocked')
        expect(remote_mirror).to be_to_retry
      end

      context 'when retries are exceeded' do
        let(:retries) { 4 }

        it 'hard fails and returns error status', :aggregate_failures do
          result = execute!

          expect(result).to eq(status: :error, message: 'The remote mirror URL is invalid: URL is blocked')
          expect(remote_mirror).to be_failed
        end
      end
    end

    describe 'resolved_address' do
      let(:import_url) { 'https://example.com/repo.git' }
      let(:resolved_ip) { '93.184.216.34' }

      before do
        allow(remote_mirror).to receive(:url).and_return(import_url)

        # Mock validate! to return the validated URI with hostname replaced by IP.
        # In reality, validate! modifies the URI to have the resolved IP as hostname.
        #
        validated_uri = Addressable::URI.parse(import_url)
        validated_uri.hostname = resolved_ip
        allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
          .and_return([validated_uri, 'example.com'])
      end

      it 'passes resolved_address to remote_mirror.update_repository' do
        expect(remote_mirror).to receive(:update_repository)
          .with(resolved_address: resolved_ip)
          .and_return(double(divergent_refs: []))

        execute!
      end

      context 'when the URL uses git protocol' do
        let(:import_url) { 'git://example.com/repo.git' }

        before do
          validated_uri = Addressable::URI.parse(import_url)
          validated_uri.hostname = resolved_ip
          allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
            .and_return([validated_uri, 'example.com'])
        end

        it 'passes resolved_address for git:// URLs' do
          expect(remote_mirror).to receive(:update_repository)
            .with(resolved_address: resolved_ip)
            .and_return(double(divergent_refs: []))

          execute!
        end
      end

      context 'when the URL is SSH' do
        let(:import_url) { 'ssh://git@example.com/repo.git' }

        before do
          validated_uri = Addressable::URI.parse(import_url)
          allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
            .and_return([validated_uri, nil])
        end

        it 'passes empty resolved_address for SSH URLs' do
          expect(remote_mirror).to receive(:update_repository)
            .with(resolved_address: '')
            .and_return(double(divergent_refs: []))

          execute!
        end
      end

      context 'when resolved_host is nil' do
        before do
          validated_uri = Addressable::URI.parse(import_url)
          allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
            .and_return([validated_uri, nil])
        end

        it 'passes empty resolved_address' do
          expect(remote_mirror).to receive(:update_repository)
            .with(resolved_address: '')
            .and_return(double(divergent_refs: []))

          execute!
        end
      end
    end

    context "when the URL local" do
      before do
        allow(remote_mirror).to receive(:url).and_return('https://localhost:3000')
      end

      context "when local requests are allowed" do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)

          # stub_application_setting does not work with `app/validators/addressable_url_validator.rb`
          settings = ApplicationSetting.new(allow_local_requests_from_web_hooks_and_services: true)
          allow(ApplicationSetting).to receive(:current).and_return(settings)
        end

        it "succeeds" do
          expect(execute![:status]).to eq(:success)
          expect(execute![:message]).to be_nil
        end
      end

      context "when local requests are not allowed" do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)

          # stub_application_setting does not work with `app/validators/addressable_url_validator.rb`
          settings = ApplicationSetting.new(allow_local_requests_from_web_hooks_and_services: false)
          allow(ApplicationSetting).to receive(:current).and_return(settings)
        end

        it "fails and returns error status" do
          expect(execute![:status]).to eq(:error)
          expect(execute![:message]).to include('The remote mirror URL is invalid:')
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
        expect(Gitlab::AppJsonLogger).not_to receive(:info)

        execute!

        expect(remote_mirror.update_status).to eq('finished')
        expect(remote_mirror.last_error).to be_nil
      end

      context 'when LFS objects fail to push' do
        before do
          expect_next_instance_of(Lfs::PushService) do |service|
            expect(service).to receive(:execute).and_return({ status: :error, message: 'unauthorized' })
          end
        end

        it 'does not fail update' do
          expect(Gitlab::AppJsonLogger).to receive(:info).with(
            hash_including(message: "Error synching remote mirror")).and_call_original

          execute!

          expect(remote_mirror.update_status).to eq('finished')
          expect(remote_mirror.last_error).to be_nil
        end
      end

      context 'with SSH repository' do
        let(:mirror) { create(:remote_mirror, project: project, enabled: true, url: mirror_url) }
        let(:mirror_url) { 'ssh://git@example.com/foo/bar.git' }

        before do
          allow(mirror)
            .to receive(:update_repository)
            .and_return(double(divergent_refs: []))
        end

        it 'does nothing to an SSH repository' do
          expect_any_instance_of(Lfs::PushService).not_to receive(:execute)

          service.execute(mirror, retries)
        end

        it 'does nothing if LFS is disabled' do
          expect(project).to receive(:lfs_enabled?) { false }

          expect_any_instance_of(Lfs::PushService).not_to receive(:execute)

          service.execute(mirror, retries)
        end

        it 'does nothing if non-password auth is specified', :aggregate_failures do
          mirror.update!(url: 'https://example.com/other.git', auth_method: 'ssh_public_key')

          expect(mirror).to receive(:password_auth?).and_call_original
          expect_any_instance_of(Lfs::PushService).not_to receive(:execute)

          service.execute(mirror, retries)
        end
      end
    end
  end
end
