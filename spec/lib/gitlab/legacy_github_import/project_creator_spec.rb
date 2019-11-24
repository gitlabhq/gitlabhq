# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::LegacyGithubImport::ProjectCreator do
  let(:user) { create(:user) }
  let(:namespace) { create(:group) }

  let(:repo) do
    OpenStruct.new(
      login: 'vim',
      name: 'vim',
      full_name: 'asd/vim',
      clone_url: 'https://gitlab.com/asd/vim.git'
    )
  end

  subject(:service) { described_class.new(repo, repo.name, namespace, user, github_access_token: 'asdffg') }

  before do
    namespace.add_owner(user)

    expect_next_instance_of(Project) do |project|
      expect(project).to receive(:add_import_job)
    end
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

    context 'when GitHub project is private' do
      it 'sets project visibility to private' do
        repo.private = true

        project = service.execute

        expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
      end
    end

    context 'when GitHub project is public' do
      it 'sets project visibility to namespace visibility level' do
        repo.private = false
        project = service.execute

        expect(project.visibility_level).to eq(namespace.visibility_level)
      end

      context 'when importing into a user namespace' do
        subject(:service) { described_class.new(repo, repo.name, user.namespace, user, github_access_token: 'asdffg') }

        it 'sets project visibility to user namespace visibility level' do
          repo.private = false
          project = service.execute

          expect(project.visibility_level).to eq(user.namespace.visibility_level)
        end
      end
    end

    context 'when visibility level is restricted' do
      context 'when GitHub project is private' do
        before do
          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PRIVATE])
          allow_any_instance_of(ApplicationSetting).to receive(:default_project_visibility).and_return(Gitlab::VisibilityLevel::INTERNAL)
        end

        it 'sets project visibility to the default project visibility' do
          repo.private = true

          project = service.execute

          expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
        end
      end

      context 'when GitHub project is public' do
        before do
          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
          allow_any_instance_of(ApplicationSetting).to receive(:default_project_visibility).and_return(Gitlab::VisibilityLevel::INTERNAL)
        end

        it 'sets project visibility to the default project visibility' do
          repo.private = false

          project = service.execute

          expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
        end
      end
    end

    context 'when GitHub project has wiki' do
      it 'does not create the wiki repository' do
        allow(repo).to receive(:has_wiki?).and_return(true)

        project = service.execute

        expect(project.wiki.repository_exists?).to eq false
      end
    end

    context 'when GitHub project does not have wiki' do
      it 'creates the wiki repository' do
        allow(repo).to receive(:has_wiki?).and_return(false)

        project = service.execute

        expect(project.wiki.repository_exists?).to eq true
      end
    end
  end
end
