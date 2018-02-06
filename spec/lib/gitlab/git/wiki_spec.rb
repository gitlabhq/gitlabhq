require 'spec_helper'

describe Gitlab::Git::Wiki do
  let(:project) { create(:project) }
  let(:user) { project.owner }
  let(:wiki) { ProjectWiki.new(project, user) }
  let(:gollum_wiki) { wiki.wiki }

  # Remove skip_gitaly_mock flag when gitaly_find_page when
  # https://gitlab.com/gitlab-org/gitaly/merge_requests/539 gets merged
  describe '#page', :skip_gitaly_mock do
    it 'returns the right page' do
      create_page('page1', 'content')
      create_page('foo/page1', 'content')

      expect(gollum_wiki.page(title: 'page1', dir: '').url_path).to eq 'page1'
      expect(gollum_wiki.page(title: 'page1', dir: 'foo').url_path).to eq 'foo/page1'

      destroy_page('page1')
      destroy_page('page1', 'foo')
    end
  end

  def create_page(name, content)
    gollum_wiki.write_page(name, :markdown, content, commit_details)
  end

  def commit_details
    Gitlab::Git::Wiki::CommitDetails.new(user.name, user.email, "test commit")
  end

  def destroy_page(title, dir = '')
    page = gollum_wiki.page(title: title, dir: dir)
    wiki.delete_page(page, "test commit")
  end
end
