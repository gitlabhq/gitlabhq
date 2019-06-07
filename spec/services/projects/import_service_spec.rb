# frozen_string_literal: true

require 'spec_helper'

describe Projects::ImportService do
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

        it 'succeeds if repository import is successful' do
          expect_any_instance_of(Gitlab::Shell).to receive(:import_repository).and_return(true)
          expect_any_instance_of(Gitlab::BitbucketImport::Importer).to receive(:execute).and_return(true)
          expect_any_instance_of(Projects::LfsPointers::LfsImportService).to receive(:execute).and_return(status: :success)

          result = subject.execute

          expect(result[:status]).to eq :success
        end

        it 'fails if repository import fails' do
          expect_any_instance_of(Gitlab::Shell).to receive(:import_repository).and_raise(Gitlab::Shell::Error.new('Failed to import the repository /a/b/c'))

          result = subject.execute

          expect(result[:status]).to eq :error
          expect(result[:message]).to eq "Error importing repository #{project.safe_import_url} into #{project.full_path} - Failed to import the repository [FILTERED]"
        end

        context 'when lfs import fails' do
          it 'logs the error' do
            error_message = 'error message'

            expect_any_instance_of(Gitlab::Shell).to receive(:import_repository).and_return(true)
            expect_any_instance_of(Gitlab::BitbucketImport::Importer).to receive(:execute).and_return(true)
            expect_any_instance_of(Projects::LfsPointers::LfsImportService).to receive(:execute).and_return(status: :error, message: error_message)
            expect(Gitlab::AppLogger).to receive(:error).with("The Lfs import process failed. #{error_message}")

            subject.execute
          end
        end

        context 'when repository import scheduled' do
          before do
            allow_any_instance_of(Gitlab::Shell).to receive(:import_repository).and_return(true)
            allow(subject).to receive(:import_data)
          end

          it 'downloads lfs objects if lfs_enabled is enabled for project' do
            allow(project).to receive(:lfs_enabled?).and_return(true)

            expect_any_instance_of(Projects::LfsPointers::LfsImportService).to receive(:execute)

            subject.execute
          end

          it 'does not download lfs objects if lfs_enabled is not enabled for project' do
            allow(project).to receive(:lfs_enabled?).and_return(false)
            expect_any_instance_of(Projects::LfsPointers::LfsImportService).not_to receive(:execute)

            subject.execute
          end
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

        result = described_class.new(project, user).execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to include('Only allowed ports are 80, 443')
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
