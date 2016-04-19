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

    destroy_wiki(project)
    subject.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(true)
  end

  it 'skips wikis when disabled' do
    project = create(:project_empty_repo, wiki_enabled: false)
    # Make sure the test would fail if it checked the wiki repo
    destroy_wiki(project)

    subject.perform(project.id)

    expect(project.reload.last_repository_check_failed).to eq(false)
  end

  def destroy_wiki(project)
    FileUtils.rm_rf(project.wiki.repository.path_to_repo)
  end
end
