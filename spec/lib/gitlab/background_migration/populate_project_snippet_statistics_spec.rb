# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateProjectSnippetStatistics do
  let(:file_name) { 'file_name.rb' }
  let(:content) { 'content' }
  let(:snippets) { table(:snippets) }
  let(:snippet_repositories) { table(:snippet_repositories) }
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:snippet_statistics) { table(:snippet_statistics) }
  let(:project_statistics) { table(:project_statistics) }
  let(:projects) { table(:projects) }
  let(:namespace_statistics) { table(:namespace_root_storage_statistics) }
  let(:routes) { table(:routes) }
  let(:repo_size) { 123456 }
  let(:expected_repo_size) { repo_size.megabytes }

  let(:user) { users.create!(id: 1, email: 'test@example.com', projects_limit: 100, username: 'test') }
  let(:group) { namespaces.create!(id: 10, type: 'Group', name: 'group1', path: 'group1') }
  let(:user_namespace) { namespaces.create!(id: 20, name: 'user', path: 'user', owner_id: user.id) }

  let(:project1) { create_project(1, 'test', group) }
  let(:project2) { create_project(2, 'test1', user_namespace) }
  let(:project3) { create_project(3, 'test2', group) }

  let!(:project_stats1) { create_project_statistics(project1) }
  let!(:project_stats2) { create_project_statistics(project2) }
  let!(:project_stats3) { create_project_statistics(project3) }

  let(:ids) { snippets.pluck(:id) }
  let(:migration) { described_class.new }

  subject do
    migration.perform(ids)

    project_stats1.reload if project_stats1.persisted?
    project_stats2.reload if project_stats2.persisted?
    project_stats3.reload if project_stats3.persisted?
  end

  before do
    allow_any_instance_of(Repository).to receive(:size).and_return(repo_size)
  end

  after do
    snippets.all.each { |s| raw_repository(s).remove }
  end

  context 'with existing user and group snippets' do
    let!(:snippet1) { create_snippet(1, project1) }
    let!(:snippet2) { create_snippet(2, project1) }
    let!(:snippet3) { create_snippet(3, project2) }
    let!(:snippet4) { create_snippet(4, project2) }
    let!(:snippet5) { create_snippet(5, project3) }

    before do
      create_snippet_statistics(2, 0)
      create_snippet_statistics(4, 123)
    end

    it 'creates/updates all snippet_statistics' do
      expect(snippet_statistics.count).to eq 2

      subject

      expect(snippet_statistics.count).to eq 5

      snippet_statistics.all.each do |stat|
        expect(stat.repository_size).to eq expected_repo_size
      end
    end

    it 'updates associated snippet project statistics' do
      expect(project_stats1.snippets_size).to be_nil
      expect(project_stats2.snippets_size).to be_nil

      subject

      snippets_size = snippet_statistics.where(snippet_id: [snippet1.id, snippet2.id]).sum(:repository_size)
      expect(project_stats1.snippets_size).to eq snippets_size

      snippets_size = snippet_statistics.where(snippet_id: [snippet3.id, snippet4.id]).sum(:repository_size)
      expect(project_stats2.snippets_size).to eq snippets_size

      snippets_size = snippet_statistics.where(snippet_id: snippet5.id).sum(:repository_size)
      expect(project_stats3.snippets_size).to eq snippets_size
    end

    it 'forces the project statistics refresh' do
      expect(migration).to receive(:update_project_statistics).exactly(3).times

      subject
    end

    it 'creates/updates the associated namespace statistics' do
      expect(migration).to receive(:update_namespace_statistics).twice.and_call_original

      subject

      expect(namespace_statistics.find_by(namespace_id: group.id).snippets_size).to eq project_stats1.snippets_size + project_stats3.snippets_size
      expect(namespace_statistics.find_by(namespace_id: user_namespace.id).snippets_size).to eq project_stats2.snippets_size
    end

    context 'when the project statistics does not exists' do
      it 'does not raise any error' do
        project_stats3.delete

        subject

        expect(namespace_statistics.find_by(namespace_id: group.id).snippets_size).to eq project_stats1.snippets_size
        expect(namespace_statistics.find_by(namespace_id: user_namespace.id).snippets_size).to eq project_stats2.snippets_size
      end
    end

    context 'when an error is raised when updating a project statistics' do
      it 'logs the error and continue execution' do
        expect(migration).to receive(:update_project_statistics).with(Project.find(project1.id)).and_raise('Error')
        expect(migration).to receive(:update_project_statistics).with(Project.find(project2.id)).and_call_original
        expect(migration).to receive(:update_project_statistics).with(Project.find(project3.id)).and_call_original

        expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |instance|
          expect(instance).to receive(:error).with(message: /Error updating statistics for project #{project1.id}/).once
        end

        subject

        expect(project_stats2.snippets_size).not_to be_nil
        expect(project_stats3.snippets_size).not_to be_nil
      end
    end

    context 'when an error is raised when updating a namespace statistics' do
      it 'logs the error and continue execution' do
        expect(migration).to receive(:update_namespace_statistics).with(Group.find(group.id)).and_raise('Error')
        expect(migration).to receive(:update_namespace_statistics).with(Namespace.find(user_namespace.id)).and_call_original

        expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |instance|
          expect(instance).to receive(:error).with(message: /Error updating statistics for namespace/).once
        end

        subject

        expect(namespace_statistics.find_by(namespace_id: user_namespace.id).snippets_size).to eq project_stats2.snippets_size
      end
    end
  end

  context 'when project snippet is in a subgroup' do
    let(:subgroup) { namespaces.create!(id: 30, type: 'Group', name: 'subgroup', path: 'subgroup', parent_id: group.id) }
    let(:project1) { create_project(1, 'test', subgroup, "#{group.path}/#{subgroup.path}/test") }
    let!(:snippet1) { create_snippet(1, project1) }

    it 'updates the root namespace statistics' do
      subject

      expect(snippet_statistics.count).to eq 1
      expect(project_stats1.snippets_size).to eq snippet_statistics.first.repository_size
      expect(namespace_statistics.find_by(namespace_id: subgroup.id)).to be_nil
      expect(namespace_statistics.find_by(namespace_id: group.id).snippets_size).to eq project_stats1.snippets_size
    end
  end

  context 'when a snippet repository is empty' do
    let!(:snippet1) { create_snippet(1, project1, with_repo: false) }
    let!(:snippet2) { create_snippet(2, project1) }

    it 'logs error and continues execution' do
      expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |instance|
        expect(instance).to receive(:error).with(message: /Invalid snippet repository/).once
      end

      subject

      expect(snippet_statistics.find_by(snippet_id: snippet1.id)).to be_nil
      expect(project_stats1.snippets_size).to eq snippet_statistics.find(snippet2.id).repository_size
    end
  end

  def create_snippet(id, project, with_repo: true)
    snippets.create!(id: id, type: 'ProjectSnippet', project_id: project.id, author_id: user.id, file_name: file_name, content: content).tap do |snippet|
      if with_repo
        allow(snippet).to receive(:disk_path).and_return(disk_path(snippet))

        TestEnv.copy_repo(snippet,
                          bare_repo: TestEnv.factory_repo_path_bare,
                          refs: TestEnv::BRANCH_SHA)

        raw_repository(snippet).create_repository
      end
    end
  end

  def create_project(id, name, namespace, path = nil)
    projects.create!(id: id, name: name, path: name.downcase.gsub(/\s/, '_'), namespace_id: namespace.id).tap do |project|
      path ||= "#{namespace.path}/#{project.path}"
      routes.create!(id: id, source_type: 'Project', source_id: project.id, path: path)
    end
  end

  def create_snippet_statistics(snippet_id, repository_size = 0)
    snippet_statistics.create!(snippet_id: snippet_id, repository_size: repository_size)
  end

  def create_project_statistics(project, snippets_size = nil)
    project_statistics.create!(id: project.id, project_id: project.id, namespace_id: project.namespace_id, snippets_size: snippets_size)
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
