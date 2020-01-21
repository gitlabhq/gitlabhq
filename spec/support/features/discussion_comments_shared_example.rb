# frozen_string_literal: true

shared_examples 'thread comments' do |resource_name|
  let(:form_selector) { '.js-main-target-form' }
  let(:dropdown_selector) { "#{form_selector} .comment-type-dropdown" }
  let(:toggle_selector) { "#{dropdown_selector} .dropdown-toggle" }
  let(:menu_selector) { "#{dropdown_selector} .dropdown-menu" }
  let(:submit_selector) { "#{form_selector} .js-comment-submit-button" }
  let(:close_selector) { "#{form_selector} .btn-comment-and-close" }
  let(:comments_selector) { '.timeline > .note.timeline-entry' }

  it 'clicking "Comment" will post a comment', :quarantine do
    expect(page).to have_selector toggle_selector

    find("#{form_selector} .note-textarea").send_keys('a')

    find(submit_selector).click

    wait_for_requests

    find(comments_selector, match: :first)
    new_comment = all(comments_selector).last

    expect(new_comment).to have_content 'a'
    expect(new_comment).not_to have_selector '.discussion'
  end

  if resource_name == 'issue'
    it "clicking 'Comment & close #{resource_name}' will post a comment and close the #{resource_name}" do
      find("#{form_selector} .note-textarea").send_keys('a')

      find(close_selector).click
      wait_for_requests

      find(comments_selector, match: :first)
      find("#{comments_selector}.system-note")
      entries = all(comments_selector)
      close_note = entries.last
      new_comment = entries[-2]

      expect(close_note).to have_content 'closed'
      expect(new_comment).not_to have_selector '.discussion'
    end
  end

  describe 'when the toggle is clicked' do
    before do
      find("#{form_selector} .note-textarea").send_keys('a')

      find(toggle_selector).click
    end

    it 'has a "Comment" item (selected by default) and "Start thread" item' do
      expect(page).to have_selector menu_selector

      find("#{menu_selector} li", match: :first)
      items = all("#{menu_selector} li")

      expect(items.first).to have_content 'Comment'
      expect(items.first).to have_content "Add a general comment to this #{resource_name}."
      expect(items.first).to have_selector '.fa-check'
      expect(items.first['class']).to match 'droplab-item-selected'

      expect(items.last).to have_content 'Start thread'
      expect(items.last).to have_content "Discuss a specific suggestion or question#{' that needs to be resolved' if resource_name == 'merge request'}."
      expect(items.last).not_to have_selector '.fa-check'
      expect(items.last['class']).not_to match 'droplab-item-selected'
    end

    it 'closes the menu when clicking the toggle or body' do
      find(toggle_selector).click

      expect(page).not_to have_selector menu_selector

      find(toggle_selector).click
      find("#{form_selector} .note-textarea").click

      expect(page).not_to have_selector menu_selector
    end

    it 'clicking the ul padding or divider should not change the text' do
      execute_script("document.querySelector('#{menu_selector}').click()")

      # on issues page, the menu closes when clicking anywhere, on other pages it will
      # remain open if clicking divider or menu padding, but should not change button action
      #
      # if dropdown menu is not toggled (and also not present),
      # it's "issue-type" dropdown
      if first(menu_selector, minimum: 0).nil?
        expect(find(dropdown_selector)).to have_content 'Comment'

        find(toggle_selector).click
        execute_script("document.querySelector('#{menu_selector} .divider').click()")
      else
        execute_script("document.querySelector('#{menu_selector}').click()")

        expect(page).to have_selector menu_selector
        expect(find(dropdown_selector)).to have_content 'Comment'

        execute_script("document.querySelector('#{menu_selector} .divider').click()")

        expect(page).to have_selector menu_selector
      end

      expect(find(dropdown_selector)).to have_content 'Comment'
    end

    describe 'when selecting "Start thread"' do
      before do
        find("#{menu_selector} li", match: :first)
        all("#{menu_selector} li").last.click
      end

      it 'updates the submit button text and closes the dropdown' do
        button = find(submit_selector)

        # on issues page, the submit input is a <button>, on other pages it is <input>
        if button.tag_name == 'button'
          expect(find(submit_selector)).to have_content 'Start thread'
        else
          expect(find(submit_selector).value).to eq 'Start thread'
        end

        expect(page).not_to have_selector menu_selector
      end

      if resource_name =~ /(issue|merge request)/
        it 'updates the close button text' do
          expect(find(close_selector)).to have_content "Start thread & close #{resource_name}"
        end

        it 'typing does not change the close button text' do
          find("#{form_selector} .note-textarea").send_keys('b')

          expect(find(close_selector)).to have_content "Start thread & close #{resource_name}"
        end
      end

      describe 'creating a thread' do
        before do
          find(submit_selector).click
          wait_for_requests

          find(comments_selector, match: :first)
        end

        def submit_reply(text)
          find("#{comments_selector} .js-vue-discussion-reply").click
          find("#{comments_selector} .note-textarea").send_keys(text)

          click_button "Comment"
          wait_for_requests
        end

        it 'clicking "Start thread" will post a thread' do
          new_comment = all(comments_selector).last

          expect(new_comment).to have_content 'a'
          expect(new_comment).to have_selector '.discussion'
        end

        if resource_name =~ /(issue|merge request)/
          it 'can be replied to' do
            submit_reply('some text')

            expect(page).to have_css('.discussion-notes .note', count: 2)
            expect(page).to have_content 'Collapse replies'
          end

          it 'can be collapsed' do
            submit_reply('another text')

            find('.js-collapse-replies').click
            expect(page).to have_css('.discussion-notes .note', count: 1)
            expect(page).to have_content '1 reply'
          end
        end

        if resource_name == 'merge request'
          let(:note_id) { find("#{comments_selector} .note:first-child", match: :first)['data-note-id'] }
          let(:reply_id) { find("#{comments_selector} .note:last-of-type", match: :first)['data-note-id'] }

          it 'can be replied to after resolving' do
            click_button "Resolve thread"
            wait_for_requests

            refresh
            wait_for_requests

            submit_reply('to reply or not reply')
          end

          it 'shows resolved thread when toggled' do
            submit_reply('a')

            click_button "Resolve thread"
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
          find(close_selector).click

          find(comments_selector, match: :first)
          find("#{comments_selector}.system-note")
          entries = all(comments_selector)
          close_note = entries.last
          new_discussion = entries[-2]

          expect(close_note).to have_content 'closed'
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

          expect(items.first).to have_content 'Comment'
          expect(items.first).not_to have_selector '.fa-check'
          expect(items.first['class']).not_to match 'droplab-item-selected'

          expect(items.last).to have_content 'Start thread'
          expect(items.last).to have_selector '.fa-check'
          expect(items.last['class']).to match 'droplab-item-selected'
        end

        describe 'when selecting "Comment"' do
          before do
            find("#{menu_selector} li", match: :first).click
          end

          it 'updates the submit button text and closes the dropdown' do
            button = find(submit_selector)

            # on issues page, the submit input is a <button>, on other pages it is <input>
            if button.tag_name == 'button'
              expect(button).to have_content 'Comment'
            else
              expect(button.value).to eq 'Comment'
            end

            expect(page).not_to have_selector menu_selector
          end

          if resource_name =~ /(issue|merge request)/
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

            expect(items.first).to have_content 'Comment'
            expect(items.first).to have_selector '.fa-check'
            expect(items.first['class']).to match 'droplab-item-selected'

            expect(items.last).to have_content 'Start thread'
            expect(items.last).not_to have_selector '.fa-check'
            expect(items.last['class']).not_to match 'droplab-item-selected'
          end
        end
      end
    end
  end

  if resource_name =~ /(issue|merge request)/
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
