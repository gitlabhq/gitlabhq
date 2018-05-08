require 'spec_helper'
require 'fileutils'

describe RepositoryCheck::SingleRepositoryWorker do
  subject { described_class.new }

  it 'passes when the project has no push events' do
    project = create(:project_empty_repo, :wiki_disabled)
    project.events.destroy_all
    break_repo(project)

    subject.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(false)
  end

  it 'fails when the project has push events and a broken repository' do
    project = create(:project_empty_repo)
    create_push_event(project)
    break_repo(project)

    subject.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(true)
  end

  it 'fails if the wiki repository is broken' do
    project = create(:project_empty_repo, :wiki_enabled)
    project.create_wiki

    # Test sanity: everything should be fine before the wiki repo is broken
    subject.perform(project.id)
    expect(project.reload.last_repository_check_failed).to eq(false)

    break_wiki(project)
    subject.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(true)
  end

  it 'skips wikis when disabled' do
    project = create(:project_empty_repo, :wiki_disabled)
    # Make sure the test would fail if the wiki repo was checked
    break_wiki(project)

    subject.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(false)
  end

  it 'creates missing wikis' do
    project = create(:project_empty_repo, :wiki_enabled)
    FileUtils.rm_rf(wiki_path(project))

    subject.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(false)
  end

  it 'does not create a wiki if the main repo does not exist at all' do
    project = create(:project_empty_repo)
    create_push_event(project)
    FileUtils.rm_rf(project.repository.path_to_repo)
    FileUtils.rm_rf(wiki_path(project))

    subject.perform(project.id)

    expect(File.exist?(wiki_path(project))).to eq(false)
  end

  def break_wiki(project)
    objects_dir = wiki_path(project) + '/objects'

    # Replace the /objects directory with a file so that the repo is
    # invalid, _and_ 'git init' cannot fix it.
    FileUtils.rm_rf(objects_dir)
    FileUtils.touch(objects_dir) if File.directory?(wiki_path(project))
  end

  def wiki_path(project)
    project.wiki.repository.path_to_repo
  end

  def create_push_event(project)
    project.events.create(action: Event::PUSHED, author_id: create(:user).id)
  end

  def break_repo(project)
    FileUtils.rm_rf(File.join(project.repository.path_to_repo, 'objects'))
  end
end
