require 'spec_helper'
require 'fileutils'

describe RepositoryCheck::SingleRepositoryWorker do
  subject { described_class.new }

  it 'fails if the wiki repository is broken' do
    project = create(:project_empty_repo, wiki_enabled: true)
    project.create_wiki

    # Test sanity: everything should be fine before the wiki repo is broken
    subject.perform(project.id)
    expect(project.reload.last_repository_check_failed).to eq(false)

    break_wiki(project)
    subject.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(true)
  end

  it 'skips wikis when disabled' do
    project = create(:project_empty_repo, wiki_enabled: false)
    # Make sure the test would fail if the wiki repo was checked
    break_wiki(project)

    subject.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(false)
  end

  it 'creates missing wikis' do
    project = create(:project_empty_repo, wiki_enabled: true)
    FileUtils.rm_rf(wiki_path(project))

    subject.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(false)
  end

  it 'does not create a wiki if the main repo does not exist at all' do
    project = create(:project_empty_repo)
    FileUtils.rm_rf(project.repository.path_to_repo)
    FileUtils.rm_rf(wiki_path(project))

    subject.perform(project.id)

    expect(File.exist?(wiki_path(project))).to eq(false)
  end

  def break_wiki(project)
    FileUtils.rm_rf(wiki_path(project) + '/objects')
  end

  def wiki_path(project)
    project.wiki.repository.path_to_repo
  end
end
