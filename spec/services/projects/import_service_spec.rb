# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportService, feature_category: :importers do
  let!(:project) { create(:project) }
  let(:user) { project.creator }

  subject { described_class.new(project, user) }

  before do
    allow(project).to receive(:lfs_enabled?).and_return(true)
  end

  describe '#async?' do
    it 'returns true for an asynchronous importer' do
      importer_class = double(:importer, async?: true)

      allow(subject).to receive(:has_importer?).and_return(true)
      allow(subject).to receive(:importer_class).and_return(importer_class)

      expect(subject).to be_async
    end

    it 'returns false for a regular importer' do
      importer_class = double(:importer, async?: false)

      allow(subject).to receive(:has_importer?).and_return(true)
      allow(subject).to receive(:importer_class).and_return(importer_class)

      expect(subject).not_to be_async
    end

    it 'returns false when the importer does not define #async?' do
      importer_class = double(:importer)

      allow(subject).to receive(:has_importer?).and_return(true)
      allow(subject).to receive(:importer_class).and_return(importer_class)

      expect(subject).not_to be_async
    end

    it 'returns false when the importer does not exist' do
      allow(subject).to receive(:has_importer?).and_return(false)

      expect(subject).not_to be_async
    end
  end

  describe '#execute' do
    context 'with unknown url' do
      before do
        project.import_url = Project::UNKNOWN_IMPORT_URL
      end

      it 'succeeds if repository is created successfully' do
        expect(project).to receive(:create_repository).and_return(true)

        result = subject.execute

        expect(result[:status]).to eq :success
      end

      it 'fails if repository creation fails' do
        expect(project).to receive(:create_repository).and_return(false)

        result = subject.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq "Error importing repository #{project.safe_import_url} into #{project.full_path} - The repository could not be created."
      end

      context 'when repository creation succeeds' do
        it 'does not download lfs files' do
          expect_any_instance_of(Projects::LfsPointers::LfsImportService).not_to receive(:execute)

          subject.execute
        end
      end
    end

    context 'with known url' do
      before do
        project.import_url = 'https://github.com/vim/vim.git'
        project.import_type = 'github'
      end

      context 'with a Github repository' do
        it 'tracks the start of import' do
          expect(Gitlab::GithubImport::ParallelImporter).to receive(:track_start_import)

          subject.execute
        end

        it 'succeeds if repository import was scheduled' do
          expect_any_instance_of(Gitlab::GithubImport::ParallelImporter)
            .to receive(:execute)
            .and_return(true)

          result = subject.execute

          expect(result[:status]).to eq :success
        end

        it 'fails if repository import was not scheduled' do
          expect_any_instance_of(Gitlab::GithubImport::ParallelImporter)
            .to receive(:execute)
            .and_return(false)

          result = subject.execute

          expect(result[:status]).to eq :error
        end

        context 'when repository import scheduled' do
          it 'does not download lfs objects' do
            expect_any_instance_of(Projects::LfsPointers::LfsImportService).not_to receive(:execute)

            subject.execute
          end
        end
      end

      context 'with a non Github repository' do
        before do
          project.import_url = 'https://bitbucket.org/vim/vim.git'
          project.import_type = 'bitbucket'
        end

        context 'when importer supports refmap' do
          before do
            project.import_type = 'gitea'
          end

          it 'succeeds if repository fetch as mirror is successful' do
            expect(project).to receive(:ensure_repository)
            expect(project.repository).to receive(:fetch_as_mirror).with('https://bitbucket.org/vim/vim.git', refmap: Gitlab::LegacyGithubImport::Importer.refmap, resolved_address: '').and_return(true)
            expect_next_instance_of(Gitlab::LegacyGithubImport::Importer) do |importer|
              expect(importer).to receive(:execute).and_return(true)
            end

            expect_next_instance_of(Projects::LfsPointers::LfsImportService) do |service|
              expect(service).to receive(:execute).and_return(status: :success)
            end

            result = subject.execute

            expect(result[:status]).to eq :success
          end

          it 'fails if repository fetch as mirror fails' do
            expect(project).to receive(:ensure_repository)
            expect(project.repository)
              .to receive(:fetch_as_mirror)
              .and_raise(Gitlab::Git::CommandError, 'Failed to import the repository /a/b/c')

            result = subject.execute

            expect(result[:status]).to eq :error
            expect(result[:message]).to eq "Error importing repository #{project.safe_import_url} into #{project.full_path} - Failed to import the repository [FILTERED]"
          end
        end

        context 'when importer does not support refmap' do
          it 'succeeds if repository import is successful' do
            expect_next_instance_of(Gitlab::BitbucketImport::ParallelImporter) do |importer|
              expect(importer).to receive(:execute).and_return(true)
            end

            result = subject.execute

            expect(result[:status]).to eq :success
          end

          it 'fails if repository import fails' do
            expect_next_instance_of(Gitlab::BitbucketImport::ParallelImporter) do |importer|
              expect(importer).to receive(:execute)
                .and_raise(Gitlab::Git::CommandError, 'Failed to import the repository /a/b/c')
            end

            result = subject.execute

            expect(result[:status]).to eq :error
            expect(result[:message]).to eq "Error importing repository #{project.safe_import_url} into #{project.full_path} - Failed to import the repository [FILTERED]"
          end
        end
      end
    end

    context 'with valid importer' do
      before do
        provider = double(:provider).as_null_object
        stub_omniauth_setting(providers: [provider])

        project.import_url = 'https://github.com/vim/vim.git'
        project.import_type = 'github'

        allow(project).to receive(:import_data).and_return(double(:import_data).as_null_object)
      end

      it 'succeeds if importer succeeds' do
        allow_any_instance_of(Gitlab::GithubImport::ParallelImporter)
          .to receive(:execute).and_return(true)

        result = subject.execute

        expect(result[:status]).to eq :success
      end

      it 'fails if importer fails' do
        allow_any_instance_of(Gitlab::GithubImport::ParallelImporter)
          .to receive(:execute)
          .and_return(false)

        result = subject.execute

        expect(result[:status]).to eq :error
      end

      context 'when importer' do
        it 'has a custom repository importer it does not download lfs objects' do
          allow(Gitlab::GithubImport::ParallelImporter).to receive(:imports_repository?).and_return(true)

          expect_any_instance_of(Projects::LfsPointers::LfsImportService).not_to receive(:execute)

          subject.execute
        end

        it 'does not have a custom repository importer downloads lfs objects' do
          allow(Gitlab::GithubImport::ParallelImporter).to receive(:imports_repository?).and_return(false)

          expect_any_instance_of(Projects::LfsPointers::LfsImportService).to receive(:execute)

          subject.execute
        end

        context 'when lfs import fails' do
          it 'logs the error' do
            error_message = 'error message'

            allow(Gitlab::GithubImport::ParallelImporter).to receive(:imports_repository?).and_return(false)
            expect_any_instance_of(Projects::LfsPointers::LfsImportService).to receive(:execute).and_return(status: :error, message: error_message)
            expect(Gitlab::AppLogger).to receive(:error).with("The Lfs import process failed. #{error_message}")

            subject.execute
          end
        end
      end
    end

    context 'with blocked import_URL' do
      it 'fails with localhost' do
        project.import_url = 'https://localhost:9000/vim/vim.git'

        result = described_class.new(project, user).execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to include('Requests to localhost are not allowed')
      end

      it 'fails with port 25' do
        project.import_url = "https://github.com:25/vim/vim.git"

        result = subject.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to include('Only allowed ports are 80, 443')
      end

      it 'fails with file scheme' do
        project.import_url = "file:///tmp/dir.git"

        result = subject.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to include('Only allowed schemes are http, https')
      end
    end

    context 'when import is a local request' do
      before do
        project.import_url = "http://127.0.0.1/group/project"
      end

      context 'when local network requests are enabled' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
        end

        it 'imports successfully' do
          expect(project.repository)
            .to receive(:import_repository)
                  .and_return(true)
          expect(subject.execute[:status]).to eq(:success)
        end
      end

      context 'when local network requests are disabled' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)
        end

        context 'when the IP is allow-listed' do
          before do
            stub_application_setting(outbound_local_requests_whitelist: ["127.0.0.1"])
          end

          it 'imports successfully' do
            expect(project.repository)
              .to receive(:import_repository)
              .and_return(true)

            expect(subject.execute[:status]).to eq(:success)
          end
        end

        context 'when the IP is not allow-listed' do
          before do
            stub_application_setting(outbound_local_requests_whitelist: [])
          end

          it 'returns an error' do
            expect(project.repository).not_to receive(:import_repository)
            expect(subject.execute).to include(
              status: :error,
              message: end_with('Requests to localhost are not allowed')
            )
          end
        end
      end
    end

    context 'when DNS rebind protection is disabled' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:dns_rebinding_protection_enabled?).and_return(false)
        project.import_url = "https://example.com/group/project"

        allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
          .with(
            project.import_url,
            ports: Project::VALID_IMPORT_PORTS,
            schemes: Project::VALID_IMPORT_PROTOCOLS,
            allow_local_network: false,
            allow_localhost: false,
            dns_rebind_protection: false,
            deny_all_requests_except_allowed: false,
            outbound_local_requests_allowlist: []
          )
          .and_return([Addressable::URI.parse("https://example.com/group/project"), nil])
      end

      it 'imports repository with url without additional resolved address' do
        expect(project.repository).to receive(:import_repository).with('https://example.com/group/project', resolved_address: '').and_return(true)

        expect_next_instance_of(Projects::LfsPointers::LfsImportService) do |service|
          expect(service).to receive(:execute).and_return(status: :success)
        end

        result = subject.execute

        expect(result[:status]).to eq(:success)
      end
    end

    context 'when DNS rebind protection is enabled' do
      before do
        stub_application_setting(http_proxy_env?: false)
        stub_application_setting(dns_rebinding_protection_enabled?: true)
      end

      context 'when https url is provided' do
        before do
          project.import_url = "https://example.com/group/project"

          allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
            .with(
              project.import_url,
              ports: Project::VALID_IMPORT_PORTS,
              schemes: Project::VALID_IMPORT_PROTOCOLS,
              allow_local_network: false,
              allow_localhost: false,
              dns_rebind_protection: true,
              deny_all_requests_except_allowed: false,
              outbound_local_requests_allowlist: []
            )
            .and_return([Addressable::URI.parse("https://172.16.123.1/group/project"), 'example.com'])
        end

        it 'imports repository with url and additional resolved address' do
          expect(project.repository).to receive(:import_repository).with('https://example.com/group/project', resolved_address: '172.16.123.1').and_return(true)

          expect_next_instance_of(Projects::LfsPointers::LfsImportService) do |service|
            expect(service).to receive(:execute).and_return(status: :success)
          end

          result = subject.execute

          expect(result[:status]).to eq(:success)
        end

        context 'when host resolves to an IPv6 address' do
          before do
            project.import_url = 'https://gitlab.com/gitlab-org/gitlab-development-kit'

            allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
              .with(
                project.import_url,
                ports: Project::VALID_IMPORT_PORTS,
                schemes: Project::VALID_IMPORT_PROTOCOLS,
                allow_local_network: false,
                allow_localhost: false,
                dns_rebind_protection: true,
                deny_all_requests_except_allowed: false,
                outbound_local_requests_allowlist: []
              )
             .and_return([Addressable::URI.parse('https://[2606:4700:90:0:f22e:fbec:5bed:a9b9]/gitlab-org/gitlab-development-kit'), 'gitlab.com'])
          end

          it 'imports repository with url and additional resolved bare IPv6 address' do
            expect(project.repository).to receive(:import_repository).with('https://gitlab.com/gitlab-org/gitlab-development-kit', resolved_address: '2606:4700:90:0:f22e:fbec:5bed:a9b9').and_return(true)

            expect_next_instance_of(Projects::LfsPointers::LfsImportService) do |service|
              expect(service).to receive(:execute).and_return(status: :success)
            end

            result = subject.execute

            expect(result[:status]).to eq(:success)
          end
        end
      end

      context 'when http url is provided' do
        before do
          project.import_url = "http://example.com/group/project"

          allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
            .with(
              project.import_url,
              ports: Project::VALID_IMPORT_PORTS,
              schemes: Project::VALID_IMPORT_PROTOCOLS,
              allow_local_network: false,
              allow_localhost: false,
              dns_rebind_protection: true,
              deny_all_requests_except_allowed: false,
              outbound_local_requests_allowlist: []
            )
            .and_return([Addressable::URI.parse("http://172.16.123.1/group/project"), 'example.com'])
        end

        it 'imports repository with url and additional resolved address' do
          expect(project.repository).to receive(:import_repository).with('http://example.com/group/project', resolved_address: '172.16.123.1').and_return(true)

          expect_next_instance_of(Projects::LfsPointers::LfsImportService) do |service|
            expect(service).to receive(:execute).and_return(status: :success)
          end

          result = subject.execute

          expect(result[:status]).to eq(:success)
        end
      end

      context 'when git address is provided' do
        before do
          project.import_url = "git://example.com/group/project.git"

          allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
            .with(
              project.import_url,
              ports: Project::VALID_IMPORT_PORTS,
              schemes: Project::VALID_IMPORT_PROTOCOLS,
              allow_local_network: false,
              allow_localhost: false,
              dns_rebind_protection: true,
              deny_all_requests_except_allowed: false,
              outbound_local_requests_allowlist: []
            )
            .and_return([Addressable::URI.parse("git://172.16.123.1/group/project"), 'example.com'])
        end

        it 'imports repository with url and without resolved address' do
          expect(project.repository).to receive(:import_repository).with('git://example.com/group/project.git', resolved_address: '').and_return(true)

          expect_next_instance_of(Projects::LfsPointers::LfsImportService) do |service|
            expect(service).to receive(:execute).and_return(status: :success)
          end

          result = subject.execute

          expect(result[:status]).to eq(:success)
        end
      end
    end
  end
end
