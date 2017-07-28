require 'spec_helper'

describe Projects::ImportService do
  let!(:project) { create(:empty_project) }
  let(:user) { project.creator }

  subject { described_class.new(project, user) }

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
        expect(result[:message]).to eq "Error importing repository #{project.import_url} into #{project.path_with_namespace} - The repository could not be created."
      end
    end

    context 'with known url' do
      before do
        project.import_url = 'https://github.com/vim/vim.git'
        project.import_type = 'github'
      end

      context 'with a Github repository' do
        it 'succeeds if repository import is successfully' do
          expect_any_instance_of(Repository).to receive(:fetch_remote).and_return(true)
          expect_any_instance_of(Gitlab::GithubImport::Importer).to receive(:execute).and_return(true)

          result = subject.execute

          expect(result[:status]).to eq :success
        end

        it 'fails if repository import fails' do
          expect_any_instance_of(Repository).to receive(:fetch_remote).and_raise(Gitlab::Shell::Error.new('Failed to import the repository'))

          result = subject.execute

          expect(result[:status]).to eq :error
          expect(result[:message]).to eq "Error importing repository #{project.import_url} into #{project.path_with_namespace} - Failed to import the repository"
        end

        it 'does not remove the GitHub remote' do
          expect_any_instance_of(Repository).to receive(:fetch_remote).and_return(true)
          expect_any_instance_of(Gitlab::GithubImport::Importer).to receive(:execute).and_return(true)

          subject.execute

          expect(project.repository.raw_repository.remote_names).to include('github')
        end
      end

      context 'with a non Github repository' do
        before do
          project.import_url = 'https://bitbucket.org/vim/vim.git'
          project.import_type = 'bitbucket'
        end

        it 'succeeds if repository import is successfully' do
          expect_any_instance_of(Gitlab::Shell).to receive(:import_repository).and_return(true)
          expect_any_instance_of(Gitlab::BitbucketImport::Importer).to receive(:execute).and_return(true)

          result = subject.execute

          expect(result[:status]).to eq :success
        end

        it 'fails if repository import fails' do
          expect_any_instance_of(Gitlab::Shell).to receive(:import_repository).and_raise(Gitlab::Shell::Error.new('Failed to import the repository'))

          result = subject.execute

          expect(result[:status]).to eq :error
          expect(result[:message]).to eq "Error importing repository #{project.import_url} into #{project.path_with_namespace} - Failed to import the repository"
        end
      end
    end

    context 'with valid importer' do
      before do
        stub_github_omniauth_provider

        project.import_url = 'https://github.com/vim/vim.git'
        project.import_type = 'github'

        allow(project).to receive(:import_data).and_return(double.as_null_object)
      end

      it 'succeeds if importer succeeds' do
        allow_any_instance_of(Repository).to receive(:fetch_remote).and_return(true)
        allow_any_instance_of(Gitlab::GithubImport::Importer).to receive(:execute).and_return(true)

        result = subject.execute

        expect(result[:status]).to eq :success
      end

      it 'flushes various caches' do
        allow_any_instance_of(Repository).to receive(:fetch_remote)
          .and_return(true)

        allow_any_instance_of(Gitlab::GithubImport::Importer).to receive(:execute)
          .and_return(true)

        expect_any_instance_of(Repository).to receive(:expire_content_cache)

        subject.execute
      end

      it 'fails if importer fails' do
        allow_any_instance_of(Repository).to receive(:fetch_remote).and_return(true)
        allow_any_instance_of(Gitlab::GithubImport::Importer).to receive(:execute).and_return(false)

        result = subject.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq "Error importing repository #{project.import_url} into #{project.path_with_namespace} - The remote data could not be imported."
      end

      it 'fails if importer raise an error' do
        allow_any_instance_of(Gitlab::Shell).to receive(:fetch_remote).and_return(true)
        allow_any_instance_of(Gitlab::GithubImport::Importer).to receive(:execute).and_raise(Projects::ImportService::Error.new('Github: failed to connect API'))

        result = subject.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq "Error importing repository #{project.import_url} into #{project.path_with_namespace} - Github: failed to connect API"
      end

      it 'expires content cache after error' do
        allow_any_instance_of(Project).to receive(:repository_exists?).and_return(false, true)

        expect_any_instance_of(Gitlab::Shell).to receive(:fetch_remote).and_raise(Gitlab::Shell::Error.new('Failed to import the repository'))
        expect_any_instance_of(Repository).to receive(:expire_content_cache)

        subject.execute
      end
    end

    context 'with blocked import_URL' do
      it 'fails with localhost' do
        project.import_url = 'https://localhost:9000/vim/vim.git'

        result = described_class.new(project, user).execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to end_with 'Blocked import URL.'
      end

      it 'fails with port 25' do
        project.import_url = "https://github.com:25/vim/vim.git"

        result = described_class.new(project, user).execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to end_with 'Blocked import URL.'
      end
    end

    def stub_github_omniauth_provider
      provider = OpenStruct.new(
        'name' => 'github',
        'app_id' => 'asd123',
        'app_secret' => 'asd123',
        'args' => {
          'client_options' => {
            'site' => 'https://github.com/api/v3',
            'authorize_url' => 'https://github.com/login/oauth/authorize',
            'token_url' => 'https://github.com/login/oauth/access_token'
          }
        }
      )

      stub_omniauth_setting(providers: [provider])
    end
  end
end
