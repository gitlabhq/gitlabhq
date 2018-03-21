require 'spec_helper'

describe Gitlab::Git::Wiki do
  let(:project) { create(:project) }
  let(:user) { project.owner }
  let(:project_wiki) { ProjectWiki.new(project, user) }
  subject { project_wiki.wiki }

  # Remove skip_gitaly_mock flag when gitaly_find_page when
  # https://gitlab.com/gitlab-org/gitlab-ce/issues/42039 is solved
  describe '#page', :skip_gitaly_mock do
    before do
      create_page('page1', 'content')
      create_page('foo/page1', 'content foo/page1')
    end

    after do
      destroy_page('page1')
      destroy_page('page1', 'foo')
    end

    it 'returns the right page' do
      expect(subject.page(title: 'page1', dir: '').url_path).to eq 'page1'
      expect(subject.page(title: 'page1', dir: 'foo').url_path).to eq 'foo/page1'
    end
  end

  def create_page(name, content)
    subject.write_page(name, :markdown, content, commit_details(name))
  end

  def commit_details(name)
    Gitlab::Git::Wiki::CommitDetails.new(user.name, user.email, "created page #{name}")
  end

  def destroy_page(title, dir = '')
    page = subject.page(title: title, dir: dir)
    project_wiki.delete_page(page, "test commit")
  end
end
