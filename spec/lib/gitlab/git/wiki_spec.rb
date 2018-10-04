require 'spec_helper'

describe Gitlab::Git::Wiki do
  let(:project) { create(:project) }
  let(:user) { project.owner }
  let(:project_wiki) { ProjectWiki.new(project, user) }
  subject { project_wiki.wiki }

  describe '#pages' do
    before do
      create_page('page1', 'content')
      create_page('page2', 'content2')
    end

    after do
      destroy_page('page1')
      destroy_page('page2')
    end

    it 'returns all the pages' do
      expect(subject.pages.count).to eq(2)
      expect(subject.pages.first.title).to eq 'page1'
      expect(subject.pages.last.title).to eq 'page2'
    end

    it 'returns only one page' do
      pages = subject.pages(limit: 1)

      expect(pages.count).to eq(1)
      expect(pages.first.title).to eq 'page1'
    end
  end

  describe '#page' do
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

  describe '#delete_page' do
    after do
      destroy_page('page1')
    end

    it 'only removes the page with the same path' do
      create_page('page1', 'content')
      create_page('*', 'content')

      subject.delete_page('*', commit_details('whatever'))

      expect(subject.pages.count).to eq 1
      expect(subject.pages.first.title).to eq 'page1'
    end
  end

  def create_page(name, content)
    subject.write_page(name, :markdown, content, commit_details(name))
  end

  def commit_details(name)
    Gitlab::Git::Wiki::CommitDetails.new(user.id, user.username, user.name, user.email, "created page #{name}")
  end

  def destroy_page(title, dir = '')
    page = subject.page(title: title, dir: dir)
    project_wiki.delete_page(page, "test commit")
  end
end
