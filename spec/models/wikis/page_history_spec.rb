# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Wikis::PageHistory, feature_category: :wiki do
  let(:project) { create(:project, :wiki_repo) }
  let(:user) { project.first_owner }
  let(:wiki) { create(:project_wiki, project: project, user: user) }
  let(:repository) { wiki.repository }

  subject(:history) { described_class.new(wiki.find_page(title)) }

  def create_page(title, content: "#{title} content\n", message: "create #{title}")
    create(:wiki_page, wiki: wiki, title: title, content: content, message: message)
  end

  def edit_page(title, content:, message:, rename_to: title)
    expect(wiki.find_page(title).update(title: rename_to, content: content, message: message)).to be(true)
  end

  def commit_actions(message, actions)
    repository.commit_files(user, branch_name: wiki.default_branch, message: message, actions: actions)
  end

  def messages(versions)
    versions.map(&:message)
  end

  shared_examples 'a history of' do |expected|
    it 'counts and lists exactly those commits, newest first', :aggregate_failures do
      expect(history.count).to eq(expected.size)
      expect(messages(history.versions)).to eq(expected)
    end
  end

  context 'when the page was never renamed' do
    let(:title) { 'plain' }

    before do
      create_page('plain')
      edit_page('plain', content: "edit 1\n", message: 'edit 1')
      create_page('unrelated')
    end

    it_behaves_like 'a history of', ['edit 1', 'create plain']
  end

  context 'when the page was renamed in the UI' do
    let(:title) { 'sub/renamed' }

    before do
      create_page('original')
      edit_page('original', content: "edit 1\n", message: 'edit 1')
      edit_page('original', rename_to: 'sub/renamed', content: "edit 1\n", message: 'rename')
      edit_page('sub/renamed', content: "edit 1\nedit 2\n", message: 'edit 2')
    end

    it_behaves_like 'a history of', ['edit 2', 'rename', 'edit 1', 'create original']
  end

  context 'when the page was renamed away and back again' do
    let(:title) { 'a' }

    before do
      create_page('a', content: "first line of a\nsecond line\n")
      edit_page('a', rename_to: 'b', content: "first line of a\nsecond line\n", message: 'rename a to b')
      edit_page('b', content: "first line of a\nsecond line\nedit on b\n", message: 'edit b')
      edit_page('b', rename_to: 'a', content: "first line of a\nsecond line\nedit on b\n", message: 'rename b to a')
    end

    it_behaves_like 'a history of', ['rename b to a', 'edit b', 'rename a to b', 'create a']
  end

  context 'when the page was moved along with its parent page' do
    let(:title) { 'new-parent/child' }

    before do
      create_page('parent')
      create_page('parent/child')
      edit_page('parent/child', content: "child edit\n", message: 'edit child')
      edit_page('parent', rename_to: 'new-parent', content: "parent content\n", message: 'rename parent')
    end

    it_behaves_like 'a history of', ['rename parent', 'edit child', 'create parent/child']
  end

  context 'when the page was created as a copy of a template' do
    let(:title) { 'meeting-notes' }
    let(:template_content) { "# Meeting\n\n## Attendees\n\n## Agenda\n\n## Actions\n" }

    before do
      create_page('templates/meeting', content: template_content)
      edit_page('templates/meeting', content: "#{template_content}\n## Notes\n", message: 'edit template')
      create_page('meeting-notes', content: "#{template_content}\n## Notes\n")
    end

    it_behaves_like 'a history of', ['create meeting-notes']
  end

  context 'when the page was deleted and recreated at the same path' do
    let(:title) { 'reborn' }

    before do
      create_page('reborn', message: 'create reborn 1')
      repository.delete_file(user, 'reborn.md', branch_name: wiki.default_branch, message: 'delete reborn')
      create_page('reborn', content: "new life\n", message: 'create reborn 2')
    end

    it_behaves_like 'a history of', ['create reborn 2', 'delete reborn', 'create reborn 1']
  end

  context 'when the page was renamed and rewritten in the same commit' do
    let(:title) { 'rewritten' }

    context 'when renamed in the UI' do
      before do
        create_page('drafted', content: "one\ntwo\nthree\n")
        edit_page('drafted', rename_to: 'rewritten', content: "something else\n", message: 'rename and rewrite')
      end

      it_behaves_like 'a history of', ['rename and rewrite', 'create drafted']
    end

    context 'when renamed by a push' do
      before do
        create_page('drafted', content: "one\ntwo\nthree\n")
        commit_actions('rename and rewrite', [
          { action: :delete, file_path: 'drafted.md' },
          { action: :create, file_path: 'rewritten.md', content: "something else entirely\n" }
        ])
      end

      it_behaves_like 'a history of', ['rename and rewrite']
    end

    context 'when the redirects file in that commit is malformed' do
      before do
        create_page('drafted', content: "one\ntwo\nthree\n")
        commit_actions('rename and rewrite', [
          { action: :delete, file_path: 'drafted.md' },
          { action: :create, file_path: 'rewritten.md', content: "something else entirely\n" },
          { action: :update, file_path: Wiki::REDIRECTS_YML, content: "drafted: [rewritten\n" }
        ])
      end

      it_behaves_like 'a history of', ['rename and rewrite']
    end

    context 'when the redirects file in that commit is not a mapping' do
      before do
        create_page('drafted', content: "one\ntwo\nthree\n")
        commit_actions('rename and rewrite', [
          { action: :delete, file_path: 'drafted.md' },
          { action: :create, file_path: 'rewritten.md', content: "something else entirely\n" },
          { action: :update, file_path: Wiki::REDIRECTS_YML, content: "- drafted\n- rewritten\n" }
        ])
      end

      it_behaves_like 'a history of', ['rename and rewrite']
    end

    context 'when the redirects file in that commit also redirects other pages' do
      before do
        create_page('drafted', content: "one\ntwo\nthree\n")
        commit_actions('rename and rewrite', [
          { action: :delete, file_path: 'drafted.md' },
          { action: :create, file_path: 'rewritten.md', content: "something else entirely\n" },
          { action: :update, file_path: Wiki::REDIRECTS_YML, content: "unrelated: elsewhere\ndrafted: rewritten\n" }
        ])
      end

      it_behaves_like 'a history of', ['rename and rewrite', 'create drafted']
    end

    context 'when there is no redirects file at that commit' do
      before do
        commit_actions('create drafted', [
          { action: :create, file_path: 'drafted.md', content: "one\ntwo\nthree\n" }
        ])
        commit_actions('rename and rewrite', [
          { action: :delete, file_path: 'drafted.md' },
          { action: :create, file_path: 'rewritten.md', content: "something else entirely\n" }
        ])
      end

      it_behaves_like 'a history of', ['rename and rewrite']
    end
  end

  context 'when the page was created without deleting anything' do
    let(:title) { 'fresh' }

    before do
      create_page('fresh')
    end

    it 'does not read the redirects file' do
      history

      expect(repository).not_to receive(:blob_at)

      history.count
    end
  end

  describe '#versions' do
    let(:title) { 'paged' }

    before do
      create_page('original-paged')
      edit_page('original-paged', rename_to: 'paged', content: "original-paged content\n", message: 'rename')
      edit_page('paged', content: "edit 1\n", message: 'edit 1')

      allow(Kaminari.config).to receive(:default_per_page).and_return(2)
    end

    it 'paginates the history', :aggregate_failures do
      expect(messages(history.versions(page: 1))).to eq(['edit 1', 'rename'])
      expect(messages(history.versions(page: 2))).to eq(['create original-paged'])
      expect(history.versions(page: 3)).to be_empty
    end
  end

  context 'when the history is longer than MAX_VERSIONS' do
    let(:title) { 'long' }

    before do
      stub_const("#{described_class}::MAX_VERSIONS", 3)
    end

    context 'when the current path alone exceeds it' do
      before do
        create_page('long-before')
        edit_page('long-before', rename_to: 'long', content: "long-before content\n", message: 'rename')
        3.times { |i| edit_page('long', content: "edit #{i}\n", message: "edit #{i}") }
      end

      it_behaves_like 'a history of', ['edit 2', 'edit 1', 'edit 0', 'rename']
    end

    context 'when an earlier path takes it over' do
      before do
        create_page('long-before')
        edit_page('long-before', content: "before edit\n", message: 'before edit')
        edit_page('long-before', rename_to: 'long', content: "before edit\n", message: 'rename')
        edit_page('long', content: "edit\n", message: 'edit')
      end

      it_behaves_like 'a history of', %w[edit rename]
    end
  end
end
