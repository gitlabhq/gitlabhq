shared_examples 'discussion comments' do |resource_name|
  let(:form_selector) { '.js-main-target-form' }
  let(:dropdown_selector) { "#{form_selector} .comment-type-dropdown" }
  let(:toggle_selector) { "#{dropdown_selector} .dropdown-toggle" }
  let(:menu_selector) { "#{dropdown_selector} .dropdown-menu" }
  let(:submit_selector) { "#{form_selector} .js-comment-submit-button" }
  let(:close_selector) { "#{form_selector} .btn-comment-and-close" }
  let(:comments_selector) { '.timeline > .note.timeline-entry' }

  it 'clicking "Comment" will post a comment' do
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

    it 'has a "Comment" item (selected by default) and "Start discussion" item' do
      expect(page).to have_selector menu_selector

      find("#{menu_selector} li", match: :first)
      items = all("#{menu_selector} li")

      expect(items.first).to have_content 'Comment'
      expect(items.first).to have_content "Add a general comment to this #{resource_name}."
      expect(items.first).to have_selector '.fa-check'
      expect(items.first['class']).to match 'droplab-item-selected'

      expect(items.last).to have_content 'Start discussion'
      expect(items.last).to have_content "Discuss a specific suggestion or question#{' that needs to be resolved' if resource_name == 'merge request'}."
      expect(items.last).not_to have_selector '.fa-check'
      expect(items.last['class']).not_to match 'droplab-item-selected'
    end

    it 'closes the menu when clicking the toggle or body' do
      find(toggle_selector).click

      expect(page).not_to have_selector menu_selector

      find(toggle_selector).click
      execute_script("document.querySelector('body').click()")

      expect(page).not_to have_selector menu_selector
    end

    it 'clicking the ul padding or divider should not change the text' do
      execute_script("document.querySelector('#{menu_selector}').click()")

      # on issues page, the menu closes when clicking anywhere, on other pages it will
      # remain open if clicking divider or menu padding, but should not change button action
      if resource_name == 'issue'
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

    describe 'when selecting "Start discussion"' do
      before do
        find("#{menu_selector} li", match: :first)
        all("#{menu_selector} li").last.click
      end

      it 'updates the submit button text and closes the dropdown' do
        # on issues page, the submit input is a <button>, on other pages it is <input>
        if resource_name == 'issue'
          expect(find(submit_selector)).to have_content 'Start discussion'
        else
          expect(find(submit_selector).value).to eq 'Start discussion'
        end

        expect(page).not_to have_selector menu_selector
      end

      if resource_name =~ /(issue|merge request)/
        it 'updates the close button text' do
          expect(find(close_selector)).to have_content "Start discussion & close #{resource_name}"
        end

        it 'typing does not change the close button text' do
          find("#{form_selector} .note-textarea").send_keys('b')

          expect(find(close_selector)).to have_content "Start discussion & close #{resource_name}"
        end
      end

      describe 'creating a discussion' do
        before do
          find(submit_selector).click
          find(comments_selector, match: :first)
        end

        it 'clicking "Start discussion" will post a discussion' do
          new_comment = all(comments_selector).last

          expect(new_comment).to have_content 'a'
          expect(new_comment).to have_selector '.discussion'
        end

        if resource_name == 'merge request'
          let(:note_id) { find("#{comments_selector} .note", match: :first)['data-note-id'] }

          it 'shows resolved discussion when toggled' do
            click_button "Resolve discussion"

            expect(page).to have_selector(".note-row-#{note_id}", visible: true)

            refresh
            click_button "Toggle discussion"

            expect(page).to have_selector(".note-row-#{note_id}", visible: true)
          end
        end
      end

      if resource_name == 'issue'
        it "clicking 'Start discussion & close #{resource_name}' will post a discussion and close the #{resource_name}" do
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

        it 'should have "Start discussion" selected' do
          find("#{menu_selector} li", match: :first)
          items = all("#{menu_selector} li")

          expect(items.first).to have_content 'Comment'
          expect(items.first).not_to have_selector '.fa-check'
          expect(items.first['class']).not_to match 'droplab-item-selected'

          expect(items.last).to have_content 'Start discussion'
          expect(items.last).to have_selector '.fa-check'
          expect(items.last['class']).to match 'droplab-item-selected'
        end

        describe 'when selecting "Comment"' do
          before do
            find("#{menu_selector} li", match: :first).click
          end

          it 'updates the submit button text and closes the dropdown' do
            # on issues page, the submit input is a <button>, on other pages it is <input>
            if resource_name == 'issue'
              expect(find(submit_selector)).to have_content 'Comment'
            else
              expect(find(submit_selector).value).to eq 'Comment'
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

          it 'should have "Comment" selected when opening the menu' do
            find(toggle_selector).click

            find("#{menu_selector} li", match: :first)
            items = all("#{menu_selector} li")

            expect(items.first).to have_content 'Comment'
            expect(items.first).to have_selector '.fa-check'
            expect(items.first['class']).to match 'droplab-item-selected'

            expect(items.last).to have_content 'Start discussion'
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

      it "should show a 'Comment & reopen #{resource_name}' button" do
        expect(find("#{form_selector} .js-note-target-reopen")).to have_content "Comment & reopen #{resource_name}"
      end

      it "should show a 'Start discussion & reopen #{resource_name}' button when 'Start discussion' is selected" do
        find(toggle_selector).click

        find("#{menu_selector} li", match: :first)
        all("#{menu_selector} li").last.click

        expect(find("#{form_selector} .js-note-target-reopen")).to have_content "Start discussion & reopen #{resource_name}"
      end
    end
  end
end
