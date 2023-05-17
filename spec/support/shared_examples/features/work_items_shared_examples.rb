# frozen_string_literal: true

RSpec.shared_examples 'work items title' do
  let(:title_selector) { '[data-testid="work-item-title"]' }

  it 'successfully shows and changes the title of the work item' do
    expect(work_item.reload.title).to eq work_item.title

    find(title_selector).set("Work item title")
    find(title_selector).native.send_keys(:return)

    wait_for_requests

    expect(work_item.reload.title).to eq 'Work item title'
  end
end

RSpec.shared_examples 'work items status' do
  let(:state_selector) { '[data-testid="work-item-state-select"]' }

  it 'successfully shows and changes the status of the work item' do
    expect(find(state_selector)).to have_content 'Open'

    find(state_selector).select("Closed")

    wait_for_requests

    expect(find(state_selector)).to have_content 'Closed'
    expect(work_item.reload.state).to eq('closed')
  end
end

RSpec.shared_examples 'work items comments' do |type|
  let(:form_selector) { '[data-testid="work-item-add-comment"]' }
  let(:textarea_selector) { '[data-testid="work-item-add-comment"] #work-item-add-or-edit-comment' }
  let(:is_mac) { page.evaluate_script('navigator.platform').include?('Mac') }
  let(:modifier_key) { is_mac ? :command : :control }
  let(:comment) { 'Test comment' }

  def set_comment
    find(form_selector).fill_in(with: comment)
  end

  it 'successfully creates and shows comments' do
    set_comment

    click_button "Comment"

    wait_for_requests

    page.within(".main-notes-list") do
      expect(page).to have_content comment
    end
  end

  context 'for work item note actions signed in user with developer role' do
    it 'shows work item note actions' do
      set_comment

      click_button "Comment"

      wait_for_requests

      page.within(".main-notes-list") do
        expect(page).to have_selector('[data-testid="work-item-note-actions"]')

        find('[data-testid="work-item-note-actions"]', match: :first).click

        expect(page).to have_selector('[data-testid="copy-link-action"]')
        expect(page).not_to have_selector('[data-testid="assign-note-action"]')
      end
    end
  end

  it 'successfully posts comments using shortcut and checks if textarea is blank when reinitiated' do
    set_comment

    send_keys([modifier_key, :enter])

    wait_for_requests

    page.within(".main-notes-list") do
      expect(page).to have_content comment
    end

    expect(find(textarea_selector)).to have_content ""
  end

  context 'when using quick actions' do
    it 'autocompletes quick actions common to all work item types', :aggregate_failures do
      click_reply_and_enter_slash

      page.within('#at-view-commands') do
        expect(page).to have_text("/title")
        expect(page).to have_text("/shrug")
        expect(page).to have_text("/tableflip")
        expect(page).to have_text("/close")
        expect(page).to have_text("/cc")
      end
    end

    context 'when a widget is enabled' do
      before do
        WorkItems::Type.default_by_type(type).widget_definitions
          .find_by_widget_type(:assignees).update!(disabled: false)
      end

      it 'autocompletes quick action for the enabled widget' do
        click_reply_and_enter_slash

        page.within('#at-view-commands') do
          expect(page).to have_text("/assign")
        end
      end
    end

    context 'when a widget is disabled' do
      before do
        WorkItems::Type.default_by_type(type).widget_definitions
          .find_by_widget_type(:assignees).update!(disabled: true)
      end

      it 'does not autocomplete quick action for the disabled widget' do
        click_reply_and_enter_slash

        page.within('#at-view-commands') do
          expect(page).not_to have_text("/assign")
        end
      end
    end

    def click_reply_and_enter_slash
      find(form_selector).fill_in(with: "/")

      wait_for_all_requests
    end
  end
end

RSpec.shared_examples 'work items assignees' do
  it 'successfully assigns the current user by searching' do
    # The button is only when the mouse is over the input
    find('[data-testid="work-item-assignees-input"]').fill_in(with: user.username)
    wait_for_requests

    # submit and simulate blur to save
    send_keys(:enter)
    find("body").click
    wait_for_requests

    expect(work_item.assignees).to include(user)
  end
end

RSpec.shared_examples 'work items labels' do
  let(:label_title_selector) { '[data-testid="labels-title"]' }

  it 'successfully assigns a label' do
    label = create(:label, project: work_item.project, title: "testing-label")

    find('[data-testid="work-item-labels-input"]').fill_in(with: label.title)
    wait_for_requests

    # submit and simulate blur to save
    send_keys(:enter)
    find(label_title_selector).click
    wait_for_requests

    expect(work_item.labels).to include(label)
  end
end

RSpec.shared_examples 'work items description' do
  it 'shows GFM autocomplete', :aggregate_failures do
    click_button "Edit description"

    find('[aria-label="Description"]').send_keys("@#{user.username}")

    wait_for_requests

    page.within('.atwho-container') do
      expect(page).to have_text(user.name)
    end
  end

  it 'autocompletes available quick actions', :aggregate_failures do
    click_button "Edit description"

    find('[aria-label="Description"]').send_keys("/")

    wait_for_requests

    page.within('#at-view-commands') do
      expect(page).to have_text("title")
      expect(page).to have_text("shrug")
      expect(page).to have_text("tableflip")
      expect(page).to have_text("close")
      expect(page).to have_text("cc")
    end
  end

  context 'on conflict' do
    let_it_be(:other_user) { create(:user) }
    let(:expected_warning) { 'Someone edited the description at the same time you did.' }

    before do
      project.add_developer(other_user)
    end

    it 'shows conflict message when description changes', :aggregate_failures do
      click_button "Edit description"

      wait_for_requests

      ::WorkItems::UpdateService.new(
        container: work_item.project,
        current_user: other_user,
        params: { description: "oh no!" }
      ).execute(work_item)

      wait_for_requests

      find('[aria-label="Description"]').send_keys("oh yeah!")

      expect(page.find('[data-testid="work-item-description-conflicts"]')).to have_text(expected_warning)

      click_button "Save and overwrite"

      expect(page.find('[data-testid="work-item-description"]')).to have_text("oh yeah!")
    end
  end
end

RSpec.shared_examples 'work items invite members' do
  include Features::InviteMembersModalHelpers

  it 'successfully assigns the current user by searching' do
    # The button is only when the mouse is over the input
    find('[data-testid="work-item-assignees-input"]').fill_in(with: 'Invite members')
    wait_for_requests

    click_button('Invite members')

    page.within invite_modal_selector do
      expect(page).to have_content("You're inviting members to the #{work_item.project.name} project")
    end
  end
end

RSpec.shared_examples 'work items milestone' do
  def set_milestone(milestone_dropdown, milestone_text)
    milestone_dropdown.click

    find('[data-testid="work-item-milestone-dropdown"] .gl-form-input', visible: true).send_keys "\"#{milestone_text}\""
    wait_for_requests

    click_button(milestone_text)
    wait_for_requests
  end

  let(:milestone_dropdown_selector) { '[data-testid="work-item-milestone-dropdown"]' }

  it 'searches and sets or removes milestone for the work item' do
    set_milestone(find(milestone_dropdown_selector), milestone.title)

    expect(page.find(milestone_dropdown_selector)).to have_text(milestone.title)

    set_milestone(find(milestone_dropdown_selector), 'No milestone')

    expect(page.find(milestone_dropdown_selector)).to have_text('Add to milestone')
  end
end

RSpec.shared_examples 'work items comment actions for guest users' do
  context 'for guest user' do
    it 'hides other actions other than copy link' do
      page.within(".main-notes-list") do
        expect(page).to have_selector('[data-testid="work-item-note-actions"]')

        find('[data-testid="work-item-note-actions"]', match: :first).click

        expect(page).to have_selector('[data-testid="copy-link-action"]')
        expect(page).not_to have_selector('[data-testid="assign-note-action"]')
      end
    end
  end
end

RSpec.shared_examples 'work items notifications' do
  let(:actions_dropdown_selector) { '[data-testid="work-item-actions-dropdown"]' }
  let(:notifications_toggle_selector) { '[data-testid="notifications-toggle-action"] > button' }

  it 'displays toast when notification is toggled' do
    find(actions_dropdown_selector).click

    page.within('[data-testid="notifications-toggle-form"]') do
      expect(page).not_to have_css(".is-checked")

      find(notifications_toggle_selector).click
      wait_for_requests

      expect(page).to have_css(".is-checked")
    end

    page.within('.gl-toast') do
      expect(find('.toast-body')).to have_content(_('Notifications turned on.'))
    end
  end
end

RSpec.shared_examples 'work items todos' do
  let(:todos_action_selector) { '[data-testid="work-item-todos-action"]' }
  let(:todos_icon_selector) { '[data-testid="work-item-todos-icon"]' }
  let(:header_section_selector) { '[data-testid="work-item-body"]' }

  def toggle_todo_action
    find(todos_action_selector).click
    wait_for_requests
  end

  it 'adds item to the list' do
    page.within(header_section_selector) do
      expect(find(todos_action_selector)['aria-label']).to eq('Add a to do')

      toggle_todo_action

      expect(find(todos_action_selector)['aria-label']).to eq('Mark as done')
    end

    page.within ".header-content span[aria-label='#{_('Todos count')}']" do
      expect(page).to have_content '1'
    end
  end

  it 'marks a todo as done' do
    page.within(header_section_selector) do
      toggle_todo_action
      toggle_todo_action
    end

    expect(find(todos_action_selector)['aria-label']).to eq('Add a to do')
    expect(page).to have_selector(".header-content span[aria-label='#{_('Todos count')}']", visible: :hidden)
  end
end

RSpec.shared_examples 'work items award emoji' do
  let(:award_section_selector) { '[data-testid="work-item-award-list"]' }
  let(:award_action_selector) { '[data-testid="award-button"]' }
  let(:selected_award_action_selector) { '[data-testid="award-button"].selected' }
  let(:emoji_picker_action_selector) { '[data-testid="emoji-picker"]' }
  let(:basketball_emoji_selector) { 'gl-emoji[data-name="basketball"]' }

  def select_emoji
    first(award_action_selector).click

    wait_for_requests
  end

  it 'adds award to the work item' do
    within(award_section_selector) do
      select_emoji

      expect(page).to have_selector(selected_award_action_selector)
      expect(first(award_action_selector)).to have_content '1'
    end
  end

  it 'removes award from work item' do
    within(award_section_selector) do
      select_emoji

      expect(first(award_action_selector)).to have_content '1'

      select_emoji

      expect(first(award_action_selector)).to have_content '0'
    end
  end

  it 'add custom award to the work item' do
    within(award_section_selector) do
      find(emoji_picker_action_selector).click
      find(basketball_emoji_selector).click

      expect(page).to have_selector(basketball_emoji_selector)
    end
  end
end
