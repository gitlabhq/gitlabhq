# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe RepositoryCheck::SingleRepositoryWorker, feature_category: :source_code_management do
  subject(:worker) { described_class.new }

  before do
    allow(::Gitlab::Git::Repository).to receive(:new).and_call_original
  end

  it 'skips when the project has no push events' do
    project = create(:project, :repository, :wiki_disabled)
    project.events.destroy_all # rubocop: disable Cop/DestroyAll

    repository = instance_double(::Gitlab::Git::Repository)
    allow(::Gitlab::Git::Repository).to receive(:new)
      .with(project.repository_storage, "#{project.disk_path}.git", anything, anything, container: project)
      .and_return(repository)

    worker.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(false)
  end

  it 'fails when the project has push events and a broken repository' do
    project = create(:project, :repository)
    create_push_event(project)

    repository = project.repository.raw
    expect(repository).to receive(:fsck).and_raise(::Gitlab::Git::Repository::GitError)
    expect(::Gitlab::Git::Repository).to receive(:new)
      .with(project.repository_storage, "#{project.disk_path}.git", anything, anything, container: project)
      .and_return(repository)

    worker.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(true)
  end

  it 'succeeds when the project repo is valid' do
    project = create(:project, :repository, :wiki_disabled)
    create_push_event(project)

    repository = project.repository.raw
    expect(repository).to receive(:fsck).and_call_original
    expect(::Gitlab::Git::Repository).to receive(:new)
      .with(project.repository_storage, "#{project.disk_path}.git", anything, anything, container: project)
      .and_return(repository)

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

    repository = project.wiki.repository.raw
    expect(repository).to receive(:fsck).and_raise(::Gitlab::Git::Repository::GitError)
    expect(::Gitlab::Git::Repository).to receive(:new)
      .with(project.repository_storage, "#{project.disk_path}.wiki.git", anything, anything, container: project.wiki)
      .and_return(repository)

    worker.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(true)
  end

  it 'skips wikis when disabled' do
    project = create(:project, :wiki_disabled)
    # Make sure the test would fail if the wiki repo was checked
    repository = instance_double(::Gitlab::Git::Repository)
    allow(::Gitlab::Git::Repository).to receive(:new)
      .with(project.repository_storage, "#{project.disk_path}.wiki.git", anything, anything, container: project)
      .and_return(repository)

    subject.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(false)
  end

  it 'creates missing wikis' do
    project = create(:project, :wiki_enabled)
    project.wiki.repository.raw.remove

    subject.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(false)
  end

  def create_push_event(project)
    project.events.create!(action: :pushed, author_id: create(:user).id)
  end
end
