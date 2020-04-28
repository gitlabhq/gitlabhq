# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::BackfillSnippetRepositories, :migration, schema: 2020_04_20_094444 do
  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:users) { table(:users) }
  let(:snippets) { table(:snippets) }
  let(:snippet_repositories) { table(:snippet_repositories) }

  let(:user_state) { 'active' }
  let(:ghost) { false }
  let(:user_type) { nil }

  let!(:user) do
    users.create(id: 1,
                 email: 'user@example.com',
                 projects_limit: 10,
                 username: 'test',
                 name: 'Test',
                 state: user_state,
                 ghost: ghost,
                 last_activity_on: 1.minute.ago,
                 user_type: user_type,
                 confirmed_at: 1.day.ago)
  end

  let!(:admin) { users.create(id: 2, email: 'admin@example.com', projects_limit: 10, username: 'admin', name: 'Admin', admin: true, state: 'active') }
  let!(:snippet_with_repo) { snippets.create(id: 1, type: 'PersonalSnippet', author_id: user.id, file_name: file_name, content: content) }
  let!(:snippet_with_empty_repo) { snippets.create(id: 2, type: 'PersonalSnippet', author_id: user.id, file_name: file_name, content: content) }
  let!(:snippet_without_repo) { snippets.create(id: 3, type: 'PersonalSnippet', author_id: user.id, file_name: file_name, content: content) }

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
        shared_examples 'admin user commits files' do
          it do
            subject

            last_commit = raw_repository(snippet).commit

            expect(last_commit.author_name).to eq admin.name
            expect(last_commit.author_email).to eq admin.email
          end
        end

        context 'when user is blocked' do
          let(:user_state) { 'blocked' }

          it_behaves_like 'admin user commits files'
        end

        context 'when user is deactivated' do
          let(:user_state) { 'deactivated' }

          it_behaves_like 'admin user commits files'
        end

        context 'when user is a ghost' do
          let(:ghost) { true }
          let(:user_type) { 'ghost' }

          it_behaves_like 'admin user commits files'
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
  end

  def blob_at(snippet, path)
    raw_repository(snippet).blob_at('master', path)
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
    raw_repository(snippet).ls_files(nil)
  end
end
