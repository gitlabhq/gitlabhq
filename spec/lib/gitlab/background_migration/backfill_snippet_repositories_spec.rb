# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSnippetRepositories, :migration, schema: 2021_03_13_045845 do
  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:users) { table(:users) }
  let(:snippets) { table(:snippets) }
  let(:snippet_repositories) { table(:snippet_repositories) }

  let(:user_state) { 'active' }
  let(:user_type) { nil }
  let(:user_name) { 'Test' }

  let!(:user) do
    users.create!(id: 1,
                 email: 'user@example.com',
                 projects_limit: 10,
                 username: 'test',
                 name: user_name,
                 state: user_state,
                 last_activity_on: 1.minute.ago,
                 user_type: user_type,
                 confirmed_at: 1.day.ago)
  end

  let!(:migration_bot) do
    users.create!(id: 100,
                 email:  "noreply+gitlab-migration-bot%s@#{Settings.gitlab.host}",
                 user_type: HasUserType::USER_TYPES[:migration_bot],
                 name: 'GitLab Migration Bot',
                 projects_limit: 10,
                 username: 'bot')
  end

  let!(:snippet_with_repo) { snippets.create!(id: 1, type: 'PersonalSnippet', author_id: user.id, file_name: file_name, content: content) }
  let!(:snippet_with_empty_repo) { snippets.create!(id: 2, type: 'PersonalSnippet', author_id: user.id, file_name: file_name, content: content) }
  let!(:snippet_without_repo) { snippets.create!(id: 3, type: 'PersonalSnippet', author_id: user.id, file_name: file_name, content: content) }

  let(:file_name) { 'file_name.rb' }
  let(:content) { 'content' }
  let(:ids) { snippets.pluck('MIN(id)', 'MAX(id)').first }
  let(:service) { described_class.new }

  subject { service.perform(*ids) }

  before do
    allow(snippet_with_repo).to receive(:disk_path).and_return(disk_path(snippet_with_repo))

    TestEnv.copy_repo(snippet_with_repo,
                      bare_repo: TestEnv.factory_repo_path_bare,
                      refs: TestEnv::BRANCH_SHA)

    raw_repository(snippet_with_empty_repo).create_repository
  end

  after do
    raw_repository(snippet_with_repo).remove
    raw_repository(snippet_without_repo).remove
    raw_repository(snippet_with_empty_repo).remove
  end

  describe '#perform' do
    it 'logs successful migrated snippets' do
      expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |instance|
        expect(instance).to receive(:info).exactly(3).times
      end

      subject
    end

    context 'when snippet has a non empty repository' do
      it 'does not perform any action' do
        expect(service).not_to receive(:create_repository_and_files).with(snippet_with_repo)

        subject
      end
    end

    shared_examples 'migration_bot user commits files' do
      it do
        subject

        last_commit = raw_repository(snippet).commit

        expect(last_commit.author_name).to eq migration_bot.name
        expect(last_commit.author_email).to eq migration_bot.email
      end
    end

    shared_examples 'commits the file to the repository' do
      context 'when author can update snippet and use git' do
        it 'creates the repository and commit the file' do
          subject

          blob = blob_at(snippet, file_name)
          last_commit = raw_repository(snippet).commit

          aggregate_failures do
            expect(blob).to be
            expect(blob.data).to eq content
            expect(last_commit.author_name).to eq user.name
            expect(last_commit.author_email).to eq user.email
          end
        end
      end

      context 'when author cannot update snippet or use git' do
        context 'when user is blocked' do
          let(:user_state) { 'blocked' }

          it_behaves_like 'migration_bot user commits files'
        end

        context 'when user is deactivated' do
          let(:user_state) { 'deactivated' }

          it_behaves_like 'migration_bot user commits files'
        end

        context 'when user is a ghost' do
          let(:user_type) { HasUserType::USER_TYPES[:ghost] }

          it_behaves_like 'migration_bot user commits files'
        end
      end
    end

    context 'when snippet has an empty repo' do
      before do
        expect(repository_exists?(snippet_with_empty_repo)).to be_truthy
      end

      it_behaves_like 'commits the file to the repository' do
        let(:snippet) { snippet_with_empty_repo }
      end
    end

    context 'when snippet does not have a repository' do
      it 'creates the repository' do
        expect { subject }.to change { repository_exists?(snippet_without_repo) }.from(false).to(true)
      end

      it_behaves_like 'commits the file to the repository' do
        let(:snippet) { snippet_without_repo }
      end
    end

    context 'when an error is raised' do
      before do
        allow(service).to receive(:create_commit).and_raise(StandardError)
      end

      it 'logs errors' do
        expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |instance|
          expect(instance).to receive(:error).exactly(3).times
        end

        subject
      end

      it "retries #{described_class::MAX_RETRIES} times the operation if it fails" do
        expect(service).to receive(:create_commit).exactly(snippets.count * described_class::MAX_RETRIES).times

        subject
      end

      it 'destroys the snippet repository' do
        expect(service).to receive(:destroy_snippet_repository).exactly(3).times.and_call_original

        subject

        expect(snippet_repositories.count).to eq 0
      end

      it 'deletes the repository on disk' do
        subject

        aggregate_failures do
          expect(repository_exists?(snippet_with_repo)).to be_falsey
          expect(repository_exists?(snippet_without_repo)).to be_falsey
          expect(repository_exists?(snippet_with_empty_repo)).to be_falsey
        end
      end
    end

    context 'with invalid file names' do
      using RSpec::Parameterized::TableSyntax

      where(:invalid_file_name, :converted_file_name) do
        'filename.js // with comment'       | 'filename-js-with-comment'
        '.git/hooks/pre-commit'             | 'git-hooks-pre-commit'
        'https://gitlab.com'                | 'https-gitlab-com'
        'html://web.title%mp4/mpg/mpeg.net' | 'html-web-title-mp4-mpg-mpeg-net'
        '../../etc/passwd'                  | 'etc-passwd'
        '.'                                 | 'snippetfile1.txt'
      end

      with_them do
        let!(:snippet_with_invalid_path) { snippets.create!(id: 4, type: 'PersonalSnippet', author_id: user.id, file_name: invalid_file_name, content: content) }
        let!(:snippet_with_valid_path) { snippets.create!(id: 5, type: 'PersonalSnippet', author_id: user.id, file_name: file_name, content: content) }
        let(:ids) { [4, 5] }

        after do
          raw_repository(snippet_with_invalid_path).remove
          raw_repository(snippet_with_valid_path).remove
        end

        it 'checks for file path errors when errors are raised' do
          expect(service).to receive(:set_file_path_error).once.and_call_original

          subject
        end

        it 'converts invalid filenames' do
          subject

          expect(blob_at(snippet_with_invalid_path, converted_file_name)).to be
        end

        it 'does not convert valid filenames on subsequent migrations' do
          subject

          expect(blob_at(snippet_with_valid_path, file_name)).to be
        end
      end
    end

    context 'when snippet content size is higher than the existing limit' do
      let(:limit) { 15 }
      let(:content) { 'a' * (limit + 1) }
      let(:snippet) { snippet_without_repo }
      let(:ids) { [snippet.id, snippet.id] }

      before do
        allow(Gitlab::CurrentSettings).to receive(:snippet_size_limit).and_return(limit)
      end

      it_behaves_like 'migration_bot user commits files'
    end

    context 'when user name is invalid' do
      let(:user_name) { '.' }
      let!(:snippet) { snippets.create!(id: 4, type: 'PersonalSnippet', author_id: user.id, file_name: file_name, content: content) }
      let(:ids) { [4, 4] }

      after do
        raw_repository(snippet).remove
      end

      it_behaves_like 'migration_bot user commits files'
    end

    context 'when both user name and snippet file_name are invalid' do
      let(:user_name) { '.' }
      let!(:other_user) do
        users.create!(id: 2,
                     email: 'user2@example.com',
                     projects_limit: 10,
                     username: 'test2',
                     name: 'Test2',
                     state: user_state,
                     last_activity_on: 1.minute.ago,
                     user_type: user_type,
                     confirmed_at: 1.day.ago)
      end

      let!(:invalid_snippet) { snippets.create!(id: 4, type: 'PersonalSnippet', author_id: user.id, file_name: '.', content: content) }
      let!(:snippet) { snippets.create!(id: 5, type: 'PersonalSnippet', author_id: other_user.id, file_name: file_name, content: content) }
      let(:ids) { [4, 5] }

      after do
        raw_repository(snippet).remove
        raw_repository(invalid_snippet).remove
      end

      it 'updates the file_name only when it is invalid' do
        subject

        expect(blob_at(invalid_snippet, 'snippetfile1.txt')).to be
        expect(blob_at(snippet, file_name)).to be
      end

      it_behaves_like 'migration_bot user commits files' do
        let(:snippet) { invalid_snippet }
      end

      it 'does not alter the commit author in subsequent migrations' do
        subject

        last_commit = raw_repository(snippet).commit

        expect(last_commit.author_name).to eq other_user.name
        expect(last_commit.author_email).to eq other_user.email
      end

      it "increases the number of retries temporarily from #{described_class::MAX_RETRIES} to #{described_class::MAX_RETRIES + 1}" do
        expect(service).to receive(:create_commit).with(Snippet.find(invalid_snippet.id)).exactly(described_class::MAX_RETRIES + 1).times.and_call_original
        expect(service).to receive(:create_commit).with(Snippet.find(snippet.id)).once.and_call_original

        subject
      end
    end
  end

  def blob_at(snippet, path)
    raw_repository(snippet).blob_at('main', path)
  end

  def repository_exists?(snippet)
    gitlab_shell.repository_exists?('default', "#{disk_path(snippet)}.git")
  end

  def raw_repository(snippet)
    Gitlab::Git::Repository.new('default',
                                "#{disk_path(snippet)}.git",
                                Gitlab::GlRepository::SNIPPET.identifier_for_container(snippet),
                                "@snippets/#{snippet.id}")
  end

  def hashed_repository(snippet)
    Storage::Hashed.new(snippet, prefix: '@snippets')
  end

  def disk_path(snippet)
    hashed_repository(snippet).disk_path
  end

  def ls_files(snippet)
    raw_repository(snippet).ls_files(snippet.default_branch)
  end
end
