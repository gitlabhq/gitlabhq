require 'spec_helper'

describe Gitlab::GithubImport::ProjectCreator, lib: true do
  let(:user) { create(:user) }
  let(:namespace) { create(:group, owner: user) }

  let(:repo) do
    OpenStruct.new(
      login: 'vim',
      name: 'vim',
      full_name: 'asd/vim',
      clone_url: 'https://gitlab.com/asd/vim.git'
    )
  end

  subject(:service) { described_class.new(repo, namespace, user, github_access_token: 'asdffg') }

  before do
    namespace.add_owner(user)
    allow_any_instance_of(Project).to receive(:add_import_job)
  end

  describe '#execute' do
    it 'creates a project' do
      expect { service.execute }.to change(Project, :count).by(1)
    end

    it 'handle GitHub credentials' do
      project = service.execute

      expect(project.import_url).to eq('https://asdffg@gitlab.com/asd/vim.git')
      expect(project.safe_import_url).to eq('https://*****@gitlab.com/asd/vim.git')
      expect(project.import_data.credentials).to eq(user: 'asdffg', password: nil)
    end

    context 'when Github project is private' do
      it 'sets project visibility to private' do
        repo.private = true

        project = service.execute

        expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
      end
    end

    context 'when Github project is public' do
      before do
        allow_any_instance_of(ApplicationSetting).to receive(:default_project_visibility).and_return(Gitlab::VisibilityLevel::INTERNAL)
      end

      it 'sets project visibility to the default project visibility' do
        repo.private = false

        project = service.execute

        expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
      end
    end
  end
end
