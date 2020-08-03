# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe RepositoryCheck::SingleRepositoryWorker do
  subject(:worker) { described_class.new }

  it 'skips when the project has no push events' do
    project = create(:project, :repository, :wiki_disabled)
    project.events.destroy_all # rubocop: disable Cop/DestroyAll
    break_project(project)

    expect(worker).not_to receive(:git_fsck)

    worker.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(false)
  end

  it 'fails when the project has push events and a broken repository' do
    project = create(:project, :repository)
    create_push_event(project)
    break_project(project)

    worker.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(true)
  end

  it 'succeeds when the project repo is valid' do
    project = create(:project, :repository, :wiki_disabled)
    create_push_event(project)

    expect(worker).to receive(:git_fsck).and_call_original

    expect do
      worker.perform(project.id)
    end.to change { project.reload.last_repository_check_at }

    expect(project.reload.last_repository_check_failed).to eq(false)
  end

  it 'fails if the wiki repository is broken' do
    project = create(:project, :repository, :wiki_enabled)
    project.create_wiki
    create_push_event(project)

    # Test sanity: everything should be fine before the wiki repo is broken
    worker.perform(project.id)
    expect(project.reload.last_repository_check_failed).to eq(false)

    break_wiki(project)
    worker.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(true)
  end

  it 'skips wikis when disabled' do
    project = create(:project, :wiki_disabled)
    # Make sure the test would fail if the wiki repo was checked
    break_wiki(project)

    subject.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(false)
  end

  it 'creates missing wikis' do
    project = create(:project, :wiki_enabled)
    TestEnv.rm_storage_dir(project.repository_storage, project.wiki.path)

    subject.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(false)
  end

  it 'does not create a wiki if the main repo does not exist at all' do
    project = create(:project, :repository)
    TestEnv.rm_storage_dir(project.repository_storage, project.path)
    TestEnv.rm_storage_dir(project.repository_storage, project.wiki.path)

    subject.perform(project.id)

    expect(TestEnv.storage_dir_exists?(project.repository_storage, project.wiki.path)).to eq(false)
  end

  def create_push_event(project)
    project.events.create!(action: :pushed, author_id: create(:user).id)
  end

  def break_wiki(project)
    Gitlab::GitalyClient::StorageSettings.allow_disk_access do
      break_repo(wiki_path(project))
    end
  end

  def wiki_path(project)
    project.wiki.repository.path_to_repo
  end

  def break_project(project)
    Gitlab::GitalyClient::StorageSettings.allow_disk_access do
      break_repo(project.repository.path_to_repo)
    end
  end

  def break_repo(repo)
    # Create or replace blob ffffffffffffffffffffffffffffffffffffffff with an empty file
    # This will make the repo invalid, _and_ 'git init' cannot fix it.
    path = File.join(repo, 'objects', 'ff')
    file = File.join(path, 'ffffffffffffffffffffffffffffffffffffff')

    FileUtils.mkdir_p(path)
    FileUtils.rm_f(file)
    FileUtils.touch(file)
  end
end
