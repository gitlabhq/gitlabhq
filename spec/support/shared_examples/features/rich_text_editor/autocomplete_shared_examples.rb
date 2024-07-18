# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'rich text editor - autocomplete' do |params = {
  with_expanded_references: true,
  with_quick_actions: true
}|
  include RichTextEditorHelpers

  describe 'autocomplete suggestions' do
    let(:suggestions_dropdown) { '[data-testid="content-editor-suggestions-dropdown"]' }

    before do
      if defined?(project)
        create(:issue, project: project, title: 'My Cool Linked Issue')
        create(:merge_request, source_project: project, source_branch: 'branch-1', title: 'My Cool Merge Request')
        create(:label, project: project, title: 'My Cool Label')
        create(:milestone, project: project, title: 'My Cool Milestone')
        create(:wiki_page, wiki: project.wiki, title: 'My Cool Wiki Page', content: 'Example')

        project.add_maintainer(create(:user, name: 'abc123', username: 'abc123'))
      else # group wikis
        project = create(:project, group: group)

        create(:issue, project: project, title: 'My Cool Linked Issue')
        create(:merge_request, source_project: project, source_branch: 'branch-1', title: 'My Cool Merge Request')
        create(:group_label, group: group, title: 'My Cool Label')
        create(:milestone, group: group, title: 'My Cool Milestone')
        create(:wiki_page, wiki: group.wiki, title: 'My Cool Wiki Page', content: 'Example')

        project.add_maintainer(create(:user, name: 'abc123', username: 'abc123'))
      end

      switch_to_content_editor

      type_in_content_editor :enter

      stub_feature_flags(disable_all_mention: false)
    end

    if params[:with_expanded_references]
      describe 'when expanding an issue reference' do
        it 'displays full reference name' do
          new_issue = create(:issue, project: project, title: 'Brand New Issue')

          type_in_content_editor "##{new_issue.iid}+s "

          expect(page).to have_text('Brand New Issue')
        end
      end

      describe 'when expanding an MR reference' do
        it 'displays full reference name' do
          new_mr = create(:merge_request, source_project: project, source_branch: 'branch-2', title: 'Brand New MR')

          type_in_content_editor "!#{new_mr.iid}+s "

          expect(page).to have_text('Brand New')
        end
      end
    end

    if params[:with_quick_actions]
      it 'shows suggestions for quick actions' do
        type_in_content_editor '/a'

        expect(find(suggestions_dropdown)).to have_text('/assign')
        expect(find(suggestions_dropdown)).to have_text('/label')
      end

      it 'adds the correct prefix and explanation for /assign' do
        type_in_content_editor '/assign'

        expect(find(suggestions_dropdown)).to have_text('/assign')
        send_keys :enter

        expect(page).to have_text('/assign @')
        type_in_content_editor 'abc'
        expect(find(suggestions_dropdown)).to have_text('abc123')
        send_keys :enter

        expect(find(content_editor_testid)).to have_text('Assigns @abc123.')
      end

      it 'adds the correct prefix and explanation for /label' do
        type_in_content_editor '/label'

        expect(find(suggestions_dropdown)).to have_text('/label')
        send_keys :enter

        expect(page).to have_text('/label ~')
        type_in_content_editor 'My'
        expect(find(suggestions_dropdown)).to have_text('My Cool Label')
        send_keys :enter

        expect(find(content_editor_testid)).to have_text('Adds a label.')
      end

      it 'adds the correct prefix and explanation for /milestone' do
        type_in_content_editor '/milestone'

        expect(find(suggestions_dropdown)).to have_text('/milestone')
        send_keys :enter

        expect(page).to have_text('/milestone %')
        type_in_content_editor 'My'
        expect(find(suggestions_dropdown)).to have_text('My Cool Milestone')
        send_keys :enter

        expect(find(content_editor_testid)).to have_text('Sets the milestone to %My Cool Milestone.')
      end

      it 'scrolls selected item into view when navigating with keyboard' do
        type_in_content_editor '/'

        expect(find(suggestions_dropdown)).to have_text('label')

        expect(dropdown_scroll_top).to be 0

        send_keys :arrow_up

        expect(dropdown_scroll_top).to be > 100
      end
    end

    it 'shows suggestions for members with descriptions' do
      type_in_content_editor '@a'

      expect(find(suggestions_dropdown)).to have_text('abc123')
      expect(find(suggestions_dropdown)).to have_text('all')
      expect(find(suggestions_dropdown)).to have_text('Group Members')

      type_in_content_editor 'bc'

      send_keys :enter

      expect(page).not_to have_css(suggestions_dropdown)
      expect(page).to have_text('@abc123')
    end

    it 'allows selecting element with tab key' do
      type_in_content_editor '@abc'

      expect(find(suggestions_dropdown)).to have_text('abc123')

      send_keys :tab

      expect(page).not_to have_css(suggestions_dropdown)
      expect(page).to have_text('@abc123')
    end

    it 'allows adding text before a username' do
      type_in_content_editor '@abc'

      expect(find(suggestions_dropdown)).to have_text('abc123')

      send_keys :tab
      expect(page).to have_text('@abc123')

      send_keys [:arrow_left, :arrow_left]
      type_in_content_editor 'foo'

      sleep 0.1 # wait for the text to be added
      switch_to_markdown_editor

      expect(page.find('textarea').value).to include('foo @abc123')
    end

    it 'allows dismissing the suggestion popup and typing more text' do
      type_in_content_editor '@ab'

      expect(find(suggestions_dropdown)).to have_text('abc123')

      send_keys :escape

      expect(page).not_to have_css(suggestions_dropdown)

      type_in_content_editor :enter
      type_in_content_editor 'foobar'

      # ensure that the texts are in separate paragraphs
      expect(page).to have_selector('p', text: '@ab')
      expect(page).to have_selector('p', text: 'foobar')
      expect(page).not_to have_selector('p', text: '@abfoobar')
    end

    it 'allows typing more text after the popup has disappeared because no suggestions match' do
      type_in_content_editor '@ab'

      expect(find(suggestions_dropdown)).to have_text('abc123')

      type_in_content_editor 'foo'
      type_in_content_editor :enter
      type_in_content_editor 'bar'

      # ensure that the texts are in separate paragraphs
      expect(page).to have_selector('p', text: '@abfoo')
      expect(page).to have_selector('p', text: 'bar')
      expect(page).not_to have_selector('p', text: '@abfoobar')
    end

    context 'when `disable_all_mention` is enabled' do
      before do
        stub_feature_flags(disable_all_mention: true)
      end

      it 'shows suggestions for members with descriptions' do
        type_in_content_editor '@a'

        expect(find(suggestions_dropdown)).to have_text('abc123')
        expect(find(suggestions_dropdown)).not_to have_text('All Group Members')

        type_in_content_editor 'bc'

        send_keys [:arrow_down, :enter]

        expect(page).not_to have_css(suggestions_dropdown)
        expect(page).to have_text('@abc123')
      end
    end

    it 'shows suggestions for merge requests' do
      type_in_content_editor '!'

      expect(find(suggestions_dropdown)).to have_text('My Cool Merge Request')

      send_keys [:arrow_down, :enter]

      expect(page).not_to have_css(suggestions_dropdown)
      expect(page).to have_text('!1')
    end

    it 'shows suggestions for issues' do
      type_in_content_editor '#'

      expect(find(suggestions_dropdown)).to have_text('My Cool Linked Issue')

      send_keys [:arrow_down, :enter]

      expect(page).not_to have_css(suggestions_dropdown)
      expect(page).to have_text('#1')
    end

    it 'shows suggestions for milestones' do
      type_in_content_editor '%'

      expect(find(suggestions_dropdown)).to have_text('My Cool Milestone')

      send_keys [:arrow_down, :enter]

      expect(page).not_to have_css(suggestions_dropdown)
      expect(page).to have_text('%My Cool Milestone')
    end

    it 'shows suggestions for emojis' do
      type_in_content_editor ':smile'

      expect(find(suggestions_dropdown)).to have_text('😃 smiley')
      expect(find(suggestions_dropdown)).to have_text('😸 smile_cat')

      send_keys :enter

      expect(page).not_to have_css(suggestions_dropdown)

      expect(page).to have_text('😄')
    end

    it 'shows suggestions for wiki pages' do
      type_in_content_editor '[[My'

      expect(find(suggestions_dropdown)).to have_text('My Cool Wiki Page')

      send_keys :enter

      expect(page).not_to have_css(suggestions_dropdown)
      expect(page).to have_text('My Cool Wiki Page')

      click_button 'Switch to plain text editing'
      wait_for_requests

      # ensure serialized markdown is in correct format (gollum/wikilinks)
      expect(page.find('textarea').value).to include('[[My Cool Wiki Page|My-Cool-Wiki-Page]]')
    end

    it 'doesn\'t show suggestions dropdown if there are no suggestions to show' do
      type_in_content_editor '%'

      expect(find(suggestions_dropdown)).to have_text('My Cool Milestone')

      type_in_content_editor 'x'

      expect(page).not_to have_css(suggestions_dropdown)
    end

    def dropdown_scroll_top
      evaluate_script("document.querySelector('#{suggestions_dropdown}').scrollTop")
    end
  end
end
