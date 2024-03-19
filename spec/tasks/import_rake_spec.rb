# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'import:github rake tasks', feature_category: :importers do
  before do
    Rake.application.rake_require 'tasks/import'
  end

  describe ':import' do
    let(:user) { create(:user) }
    let(:user_name) { user.username }
    let(:github_repo) { 'github_user/repo' }
    let(:target_namespace) { user.namespace_path }
    let(:project_path) { "#{target_namespace}/project_name" }

    before do
      allow($stdin).to receive(:getch)

      stub_request(:get, 'https://api.github.com/user/repos?per_page=100')
        .to_return(
          status: 200,
          body: [{ id: 1, full_name: 'github_user/repo', clone_url: 'https://github.com/user/repo.git' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    context 'when importing a single project' do
      subject(:import_task) { run_rake_task('import:github', 'token', user_name, project_path, github_repo) }

      context 'when all inputs are correct' do
        it 'imports a repository' do
          expect_next_instance_of(Gitlab::GithubImport::SequentialImporter) do |importer|
            expect(importer).to receive(:execute)
          end

          expect_next_instance_of(Project) do |project|
            expect(project).to receive(:after_import)
          end

          import_task
        end
      end

      context 'when project path is invalid' do
        let(:project_path) { target_namespace }

        it 'aborts with an error' do
          expect { import_task }.to raise_error(SystemExit, 'Project path must be: namespace(s)/project_name')
        end
      end

      context 'when user is not found' do
        let(:user_name) { 'unknown_user' }

        it 'aborts with an error' do
          expect { import_task }.to raise_error("GitLab user #{user_name} not found. Please specify a valid username.")
        end
      end

      context 'when github repo is not found' do
        let(:github_repo) { 'github_user/unknown_repo' }

        it 'aborts with an error' do
          expect { import_task }.to raise_error('No repo found!')
        end
      end

      context 'when namespace to import repo into does not exists' do
        let(:target_namespace) { 'unknown_namespace_path' }

        it 'aborts with an error' do
          expect do
            import_task
          end.to raise_error(s_('GithubImport|Namespace or group to import repository into does not exist.'))
        end
      end
    end

    context 'when importing multiple projects' do
      subject(:import_task) { run_rake_task('import:github', 'token', user_name, project_path) }

      context 'when user enters github repo id that exists' do
        before do
          allow($stdin).to receive(:gets).and_return("1\n")
        end

        it 'imports a repository' do
          expect_next_instance_of(Gitlab::GithubImport::SequentialImporter) do |importer|
            expect(importer).to receive(:execute)
          end

          expect_next_instance_of(Project) do |project|
            expect(project).to receive(:after_import)
          end

          import_task
        end
      end

      context 'when user enters github repo id that does not exists' do
        before do
          allow($stdin).to receive(:gets).and_return("2\n")
        end

        it 'aborts with an error' do
          expect { import_task }.to raise_error('No repo found!')
        end
      end
    end
  end
end
