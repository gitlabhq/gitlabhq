# frozen_string_literal: true

RSpec.shared_examples 'thread comments for commit and snippet' do |resource_name|
  let(:form_selector) { '.js-main-target-form' }
  let(:dropdown_selector) { "#{form_selector} .comment-type-dropdown" }
  let(:toggle_selector) { "#{dropdown_selector} .gl-new-dropdown-toggle" }
  let(:menu_selector) { "#{dropdown_selector} .gl-new-dropdown-contents" }
  let(:submit_selector) { "#{form_selector} .js-comment-submit-button > button:first-child" }
  let(:close_selector) { "#{form_selector} .btn-comment-and-close" }
  let(:comments_selector) { '.timeline > .note.timeline-entry:not(.being-posted)' }
  let(:comment) { 'My comment' }

  it 'clicking "Comment" will post a comment' do
    wait_for_all_requests

    expect(page).to have_selector toggle_selector

    find("#{form_selector} .note-textarea").send_keys(comment)

    find('.js-comment-button').click

    wait_for_all_requests

    expect(page).to have_content(comment)

    new_comment = all(comments_selector).last

    expect(new_comment).not_to have_selector '.discussion'
  end

  describe 'when the toggle is clicked' do
    before do
      find("#{form_selector} .note-textarea").send_keys(comment)

      find(toggle_selector).click

      wait_for_all_requests
    end

    it 'has a "Comment" item (selected by default) and "Start thread" item' do
      expect(page).to have_selector menu_selector

      find("#{menu_selector} li", match: :first)
      items = all("#{menu_selector} li")

      expect(items.first).to have_content 'Comment'
      expect(items.first).to have_content "Add a general comment to this #{resource_name}."
      expect(items.first).to have_selector '[data-testid="dropdown-item-checkbox"]'

      expect(items.last).to have_content 'Start thread'
      expect(items.last).to have_content "Discuss a specific suggestion or question#{' that needs to be resolved' if resource_name == 'merge request'}."
      expect(items.last).not_to have_selector '[data-testid="dropdown-item-checkbox"]'
    end

    it 'closes the menu when clicking the toggle or body' do
      find(toggle_selector).click

      expect(page).not_to have_selector menu_selector

      find(toggle_selector).click
      find("#{form_selector} .note-textarea").click

      expect(page).not_to have_selector menu_selector
    end

    describe 'when selecting "Start thread"' do
      before do
        find("#{menu_selector} li", match: :first)
        all("#{menu_selector} li").last.click
      end

      it 'updates the submit button text and closes the dropdown' do
        expect(find(submit_selector).text).to eq 'Start thread'

        expect(page).not_to have_selector menu_selector
      end

      describe 'creating a thread' do
        before do
          find(submit_selector).click
          wait_for_requests

          find(comments_selector, match: :first)
        end

        def submit_reply(text)
          find("#{comments_selector} [data-testid=\"discussion-reply-tab\"]").click
          find("#{comments_selector} .note-textarea").send_keys(text)

          find("#{comments_selector} .js-comment-button").click
          wait_for_requests
        end

        it 'clicking "Start thread" will post a thread' do
          expect(page).to have_content(comment)

          new_comment = all(comments_selector).last

          expect(new_comment).to have_selector('.discussion')
        end
      end

      describe 'when opening the menu' do
        before do
          find(toggle_selector).click
        end

        it 'has "Start thread" selected' do
          find("#{menu_selector} li", match: :first)
          items = all("#{menu_selector} li")

          expect(items.first).to have_content 'Comment'
          expect(items.first).not_to have_selector '[data-testid="dropdown-item-checkbox"]'

          expect(items.last).to have_content 'Start thread'
          expect(items.last).to have_selector '[data-testid="dropdown-item-checkbox"]'
        end

        describe 'when selecting "Comment"' do
          before do
            find("#{menu_selector} li", match: :first).click
          end

          it 'updates the submit button text and closes the dropdown' do
            button = find(submit_selector)

            expect(button.text).to eq 'Comment'

            expect(page).not_to have_selector menu_selector
          end

          it 'has "Comment" selected when opening the menu', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/196825' do
            find(toggle_selector).click

            find("#{menu_selector} li", match: :first)
            items = all("#{menu_selector} li")

            aggregate_failures do
              expect(items.first).to have_content 'Comment'
              expect(items.first).to have_selector '[data-testid="dropdown-item-checkbox"]'

              expect(items.last).to have_content 'Start thread'
              expect(items.last).not_to have_selector '[data-testid="dropdown-item-checkbox"]'
            end
          end
        end
      end
    end
  end
end

RSpec.shared_examples 'thread comments for issue, epic and merge request' do |resource_name|
  let(:form_selector) { '.js-main-target-form' }
  let(:dropdown_selector) { "#{form_selector} .comment-type-dropdown" }
  let(:toggle_selector) { "#{dropdown_selector} .gl-new-dropdown-toggle" }
  let(:menu_selector) { "#{dropdown_selector} .gl-new-dropdown-contents" }
  let(:submit_selector) { "#{form_selector} .js-comment-submit-button > button:first-child" }
  let(:close_selector) { "#{form_selector} .btn-comment-and-close" }
  let(:comments_selector) { '.timeline > .note.timeline-entry:not(.being-posted)' }
  let(:comment) { 'My comment' }

  it 'clicking "Comment" will post a comment' do
    expect(page).to have_selector toggle_selector

    find("#{form_selector} .note-textarea").send_keys(comment)

    find(submit_selector).click

    wait_for_all_requests

    expect(page).to have_content(comment)

    new_comment = all(comments_selector).last

    expect(new_comment).not_to have_selector '.discussion'
  end

  if resource_name == 'issue'
    it "clicking 'Comment & close #{resource_name}' will post a comment and close the #{resource_name}" do
      find("#{form_selector} .note-textarea").send_keys(comment)

      click_button 'Comment & close issue'

      wait_for_all_requests

      expect(page).to have_content(comment)
      expect(page).to have_content "#{user.name} closed"

      new_comment = all(comments_selector).last

      expect(new_comment).not_to have_selector '.discussion'
    end
  end

  describe 'when the toggle is clicked' do
    before do
      find("#{form_selector} .note-textarea").send_keys(comment)

      find(toggle_selector).click
    end

    it 'has a "Comment" item (selected by default) and "Start thread" item' do
      expect(page).to have_selector menu_selector

      find("#{menu_selector} li", match: :first)
      items = all("#{menu_selector} li")

      expect(page).to have_selector("#{dropdown_selector}[data-track-label='comment_button']")

      expect(items.first).to have_content 'Comment'
      expect(items.first).to have_content "Add a general comment to this #{resource_name}."

      expect(items.last).to have_content 'Start thread'
      expect(items.last).to have_content "Discuss a specific suggestion or question#{' that needs to be resolved' if resource_name == 'merge request'}."
    end

    it 'closes the menu when clicking the toggle or body' do
      find(toggle_selector).click

      expect(page).not_to have_selector menu_selector

      find(toggle_selector).click
      find("#{form_selector} .note-textarea").click

      expect(page).not_to have_selector menu_selector
    end

    describe 'when selecting "Start thread"' do
      before do
        find("#{menu_selector} li", match: :first)
        all("#{menu_selector} li").last.click
      end

      describe 'creating a thread' do
        before do
          find(submit_selector).click
          wait_for_requests

          find(comments_selector, match: :first)
        end

        def submit_reply(text)
          find("#{comments_selector} [data-testid=\"discussion-reply-tab\"]").click
          find("#{comments_selector} .note-textarea").send_keys(text)

          # .js-comment-button here refers to the reply button in note_form.vue
          find("#{comments_selector} .js-comment-button").click
          wait_for_requests
        end

        it 'clicking "Start thread" will post a thread and show a reply component' do
          expect(page).to have_content(comment)

          new_comment = all(comments_selector).last

          expect(new_comment).to have_selector('.discussion')
          expect(new_comment).to have_css('.discussion-with-resolve-btn')
        end

        if /(issue|merge request)/.match?(resource_name)
          it 'can be replied to' do
            submit_reply('some text')

            expect(page).to have_css('.discussion-notes .note', count: 2)
            expect(page).to have_content 'Collapse replies'
          end

          it 'can be collapsed' do
            submit_reply('another text')

            click_button s_('Notes|Collapse replies'), match: :first
            expect(page).to have_css('.discussion-notes .note', count: 1)
            expect(page).to have_content '1 reply'
          end

          let(:note_id) { find("#{comments_selector} .note:first-child", match: :first)['data-note-id'] }
          let(:reply_id) { all("#{comments_selector} [data-note-id]")[1]['data-note-id'] }

          it 'can be replied to after resolving' do
            find('button[data-testid="resolve-discussion-button"]').click
            wait_for_requests

            refresh
            wait_for_requests

            submit_reply('to reply or not reply')
          end

          it 'shows resolved thread when toggled' do
            submit_reply('a')

            find('button[data-testid="resolve-discussion-button"]').click
            wait_for_requests

            expect(page).to have_selector(".note-row-#{note_id}", visible: true)

            refresh
            click_button "1 reply"

            expect(page).to have_selector(".note-row-#{reply_id}", visible: true)
          end
        end
      end

      if resource_name == 'issue'
        it "clicking 'Start thread & close #{resource_name}' will post a thread and close the #{resource_name}" do
          click_button 'Start thread & close issue'

          expect(page).to have_content(comment)
          expect(page).to have_content "#{user.name} closed"

          new_discussion = all(comments_selector)[-1]

          expect(new_discussion).to have_selector '.discussion'
        end
      end

      describe 'when opening the menu' do
        before do
          find(toggle_selector).click
        end

        it 'has "Start thread" selected' do
          find("#{menu_selector} li", match: :first)
          items = all("#{menu_selector} li")

          expect(page).to have_selector("#{dropdown_selector}[data-track-label='start_thread_button']")

          expect(items.first).to have_content 'Comment'

          expect(items.last).to have_content 'Start thread'
        end

        describe 'when selecting "Comment"' do
          before do
            find("#{menu_selector} li", match: :first).click
          end

          it 'updates the submit button text and closes the dropdown' do
            button = find(submit_selector)

            expect(button).to have_content 'Comment'

            expect(page).not_to have_selector menu_selector
          end

          if /(issue|merge request)/.match?(resource_name)
            it 'updates the close button text' do
              expect(find(close_selector)).to have_content "Comment & close #{resource_name}"
            end

            it 'typing does not change the close button text' do
              find("#{form_selector} .note-textarea").send_keys('b')

              expect(find(close_selector)).to have_content "Comment & close #{resource_name}"
            end
          end

          it 'has "Comment" selected when opening the menu' do
            find(toggle_selector).click

            find("#{menu_selector} li", match: :first)
            items = all("#{menu_selector} li")

            expect(page).to have_selector("#{dropdown_selector}[data-track-label='comment_button']")

            expect(items.first).to have_content 'Comment'

            expect(items.last).to have_content 'Start thread'
          end
        end
      end
    end
  end

  if /(issue|merge request)/.match?(resource_name)
    describe "on a closed #{resource_name}" do
      before do
        find("#{form_selector} .js-note-target-close").click
        wait_for_requests

        find("#{form_selector} .note-textarea").send_keys('a')
      end

      it "shows a 'Comment & reopen #{resource_name}' button" do
        expect(find("#{form_selector} .js-note-target-reopen")).to have_content "Comment & reopen #{resource_name}"
      end

      it "shows a 'Start thread & reopen #{resource_name}' button when 'Start thread' is selected" do
        find(toggle_selector).click

        find("#{menu_selector} li", match: :first)
        all("#{menu_selector} li").last.click

        expect(find("#{form_selector} .js-note-target-reopen")).to have_content "Start thread & reopen #{resource_name}"
      end
    end
  end
end
