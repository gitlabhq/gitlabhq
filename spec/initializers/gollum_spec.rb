require 'spec_helper'

describe 'gollum' do
  let(:project) { create(:project) }
  let(:user) { project.owner }
  let(:wiki) { ProjectWiki.new(project, user) }
  let(:gollum_wiki) { Gollum::Wiki.new(wiki.repository.path) }

  before do
    create_page(page_name, 'content1')
  end

  after do
    destroy_page(page_name)
  end

  context 'with simple paths' do
    let(:page_name) { 'page1' }

    it 'returns the entry hash if it matches the file name' do
      expect(tree_entry(page_name)).not_to be_nil
    end

    it 'returns nil if the path does not fit completely' do
      expect(tree_entry("foo/#{page_name}")).to be_nil
    end
  end

  context 'with complex paths' do
    let(:page_name) { '/foo/bar/page2' }

    it 'returns the entry hash if it matches the file name' do
      expect(tree_entry(page_name)).not_to be_nil
    end

    it 'returns nil if the path does not fit completely' do
      expect(tree_entry("foo1/bar/page2")).to be_nil
      expect(tree_entry("foo/bar1/page2")).to be_nil
    end
  end

  def tree_entry(name)
    gollum_wiki.repo.git.tree_entry(wiki_commits[0].commit, name + '.md')
  end

  def wiki_commits
    gollum_wiki.repo.commits
  end

  def commit_details
    Gitlab::Git::Wiki::CommitDetails.new(user.name, user.email, "test commit")
  end

  def create_page(name, content)
    wiki.wiki.write_page(name, :markdown, content, commit_details)
  end

  def destroy_page(name)
    page = wiki.find_page(name).page
    wiki.delete_page(page, "test commit")
  end
end
