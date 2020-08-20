# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulatePersonalSnippetStatistics do
  let(:file_name) { 'file_name.rb' }
  let(:content) { 'content' }
  let(:snippets) { table(:snippets) }
  let(:snippet_repositories) { table(:snippet_repositories) }
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:snippet_statistics) { table(:snippet_statistics) }
  let(:namespace_statistics) { table(:namespace_root_storage_statistics) }
  let(:routes) { table(:routes) }
  let(:repo_size) { 123456 }
  let(:expected_repo_size) { repo_size.megabytes }

  let(:user1) { users.create!(id: 1, email: 'test@example.com', projects_limit: 100, username: 'test1') }
  let(:user2) { users.create!(id: 2, email: 'test2@example.com', projects_limit: 100, username: 'test2') }
  let!(:user1_namespace) { namespaces.create!(id: 1, name: 'user1', path: 'user1', owner_id: user1.id) }
  let!(:user2_namespace) { namespaces.create!(id: 2, name: 'user2', path: 'user2', owner_id: user2.id) }
  let(:user1_namespace_statistics) { namespace_statistics.find_by(namespace_id: user1_namespace.id) }
  let(:user2_namespace_statistics) { namespace_statistics.find_by(namespace_id: user2_namespace.id) }

  let(:ids) { snippets.pluck(:id) }
  let(:migration) { described_class.new }

  subject do
    migration.perform(ids)
  end

  before do
    allow_any_instance_of(Repository).to receive(:size).and_return(repo_size)
  end

  after do
    snippets.all.each { |s| raw_repository(s).remove }
  end

  context 'with existing personal snippets' do
    let!(:snippet1) { create_snippet(1, user1) }
    let!(:snippet2) { create_snippet(2, user1) }
    let!(:snippet3) { create_snippet(3, user2) }
    let!(:snippet4) { create_snippet(4, user2) }

    before do
      create_snippet_statistics(2, 0)
      create_snippet_statistics(4, 123)
    end

    it 'creates/updates all snippet_statistics' do
      expect { subject }.to change { snippet_statistics.count }.from(2).to(4)

      expect(snippet_statistics.pluck(:repository_size)).to be_all(expected_repo_size)
    end

    it 'creates/updates the associated namespace statistics' do
      expect(migration).to receive(:update_namespace_statistics).twice.and_call_original

      subject

      stats = snippet_statistics.where(snippet_id: [snippet1, snippet2]).sum(:repository_size)
      expect(user1_namespace_statistics.snippets_size).to eq stats

      stats = snippet_statistics.where(snippet_id: [snippet3, snippet4]).sum(:repository_size)
      expect(user2_namespace_statistics.snippets_size).to eq stats
    end

    context 'when an error is raised when updating a namespace statistics' do
      it 'logs the error and continue execution' do
        expect_next_instance_of(Namespaces::StatisticsRefresherService) do |instance|
          expect(instance).to receive(:execute).with(Namespace.find(user1_namespace.id)).and_raise('Error')
        end

        expect_next_instance_of(Namespaces::StatisticsRefresherService) do |instance|
          expect(instance).to receive(:execute).and_call_original
        end

        expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |instance|
          expect(instance).to receive(:error).with(message: /Error updating statistics for namespace/).once
        end

        subject

        expect(user1_namespace_statistics).to be_nil

        stats = snippet_statistics.where(snippet_id: [snippet3, snippet4]).sum(:repository_size)
        expect(user2_namespace_statistics.snippets_size).to eq stats
      end
    end
  end

  context 'when a snippet repository is empty' do
    let!(:snippet1) { create_snippet(1, user1, with_repo: false) }
    let!(:snippet2) { create_snippet(2, user1) }

    it 'logs error and continues execution' do
      expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |instance|
        expect(instance).to receive(:error).with(message: /Invalid snippet repository/).once
      end

      subject

      expect(snippet_statistics.find_by(snippet_id: snippet1.id)).to be_nil
      expect(user1_namespace_statistics.snippets_size).to eq expected_repo_size
    end
  end

  def create_snippet(id, author, with_repo: true)
    snippets.create!(id: id, type: 'PersonalSnippet', author_id: author.id, file_name: file_name, content: content).tap do |snippet|
      if with_repo
        allow(snippet).to receive(:disk_path).and_return(disk_path(snippet))

        TestEnv.copy_repo(snippet,
                          bare_repo: TestEnv.factory_repo_path_bare,
                          refs: TestEnv::BRANCH_SHA)

        raw_repository(snippet).create_repository
      end
    end
  end

  def create_snippet_statistics(snippet_id, repository_size = 0)
    snippet_statistics.create!(snippet_id: snippet_id, repository_size: repository_size)
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
end
