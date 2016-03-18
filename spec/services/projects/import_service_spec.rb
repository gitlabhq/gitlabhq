require 'spec_helper'

describe Projects::ImportService, services: true do
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
        expect(result[:message]).to eq 'The repository could not be created.'
      end
    end

    context 'with known url' do
      before do
        project.import_url = 'https://github.com/vim/vim.git'
      end

      it 'succeeds if repository import is successfully' do
        expect_any_instance_of(Gitlab::Shell).to receive(:import_repository).with(project.path_with_namespace, project.import_url).and_return(true)

        result = subject.execute

        expect(result[:status]).to eq :success
      end

      it 'fails if repository import fails' do
        expect_any_instance_of(Gitlab::Shell).to receive(:import_repository).with(project.path_with_namespace, project.import_url).and_raise(Gitlab::Shell::Error.new('Failed to import the repository'))

        result = subject.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq 'Failed to import the repository'
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
        expect_any_instance_of(Gitlab::Shell).to receive(:import_repository).with(project.path_with_namespace, project.import_url).and_return(true)
        expect_any_instance_of(Gitlab::GithubImport::Importer).to receive(:execute).and_return(true)

        result = subject.execute

        expect(result[:status]).to eq :success
      end

      it 'fails if importer fails' do
        expect_any_instance_of(Gitlab::Shell).to receive(:import_repository).with(project.path_with_namespace, project.import_url).and_return(true)
        expect_any_instance_of(Gitlab::GithubImport::Importer).to receive(:execute).and_return(false)

        result = subject.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq 'The remote data could not be imported.'
      end

      it 'fails if importer raise an error' do
        expect_any_instance_of(Gitlab::Shell).to receive(:import_repository).with(project.path_with_namespace, project.import_url).and_return(true)
        expect_any_instance_of(Gitlab::GithubImport::Importer).to receive(:execute).and_raise(Projects::ImportService::Error.new('Github: failed to connect API'))

        result = subject.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq 'Github: failed to connect API'
      end
    end

    def stub_github_omniauth_provider
      provider = OpenStruct.new(
        name: 'github',
        app_id: 'asd123',
        app_secret: 'asd123'
      )

      Gitlab.config.omniauth.providers << provider
    end
  end
end
