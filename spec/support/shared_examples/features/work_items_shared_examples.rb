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

RSpec.shared_examples 'work items toggle status button' do
  it 'successfully shows and changes the status of the work item' do
    click_button 'Close', match: :first

    expect(page).to have_button 'Reopen'
    expect(work_item.reload.state).to eq('closed')
  end
end

RSpec.shared_examples 'work items comments' do |type|
  let(:is_mac) { page.evaluate_script('navigator.platform').include?('Mac') }
  let(:modifier_key) { is_mac ? :command : :control }

  def set_comment
    fill_in _('Add a reply'), with: 'Test comment'
  end

  it 'successfully creates and shows comments' do
    set_comment
    click_button "Comment"

    page.within(".main-notes-list") do
      expect(page).to have_text 'Test comment'
    end
  end

  it 'successfully updates existing comments' do
    set_comment
    click_button "Comment"
    click_button _('Edit comment')
    send_keys(" updated")
    click_button _('Save comment')

    page.within(".main-notes-list") do
      expect(page).to have_content "Test comment updated"
    end
  end

  context 'for work item note actions signed in user with developer role' do
    let_it_be(:owner) { create(:user) }

    before do
      project.add_owner(owner)
    end

    it 'shows work item note actions' do
      set_comment
      send_keys([modifier_key, :enter])

      page.within(".main-notes-list") do
        expect(page).to have_text 'Test comment'
      end

      page.within('.timeline-entry.note.note-wrapper.note-comment:last-child') do
        click_button _('More actions')

        expect(page).to have_button _('Copy link')
        expect(page).to have_button _('Assign to commenting user')
        expect(page).to have_button _('Delete comment')
        expect(page).to have_button _('Edit comment')
      end
    end
  end

  it 'successfully posts comments using shortcut and checks if textarea is blank when reinitiated' do
    set_comment
    send_keys([modifier_key, :enter])

    page.within(".main-notes-list") do
      expect(page).to have_content 'Test comment'
    end
    expect(page).to have_field _('Add a reply'), with: ''
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
      fill_in _('Add a reply'), with: '/'
    end
  end
end

RSpec.shared_examples 'work items assignees' do
  it 'successfully assigns the current user by searching',
    quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/413074' do
    # The button is only when the mouse is over the input
    find('[data-testid="work-item-assignees-input"]').fill_in(with: user.username)
    wait_for_requests
    # submit and simulate blur to save
    send_keys(:enter)
    find("body").click
    wait_for_requests

    expect(work_item.reload.assignees).to include(user)
  end

  it 'successfully assigns the current user by clicking `Assign myself` button' do
    find('[data-testid="work-item-assignees-input"]').hover
    click_button _('Assign yourself')

    expect(work_item.reload.assignees).to include(user)
  end

  it 'successfully removes all users on clear all button click' do
    find('[data-testid="work-item-assignees-input"]').hover
    click_button _('Assign yourself')

    expect(work_item.reload.assignees).to include(user)

    find('[data-testid="work-item-assignees-input"]').click
    click_button 'Clear all'
    find("body").click
    wait_for_requests

    expect(work_item.reload.assignees).not_to include(user)
  end

  it 'successfully removes user on clicking badge cross button' do
    find('[data-testid="work-item-assignees-input"]').hover
    click_button _('Assign yourself')

    expect(work_item.reload.assignees).to include(user)

    within('[data-testid="work-item-assignees-input"]') do
      click_button 'Close'
    end
    find("body").click
    wait_for_requests

    expect(work_item.reload.assignees).not_to include(user)
  end

  it 'updates the assignee in real-time' do
    Capybara::Session.new(:other_session)

    using_session :other_session do
      visit work_items_path
      expect(work_item.reload.assignees).not_to include(user)
    end

    find('[data-testid="work-item-assignees-input"]').hover
    click_button _('Assign yourself')

    expect(work_item.reload.assignees).to include(user)
    using_session :other_session do
      expect(work_item.reload.assignees).to include(user)
    end
  end
end

RSpec.shared_examples 'work items labels' do
  let(:label_title_selector) { '[data-testid="labels-title"]' }
  let(:labels_input_selector) { '[data-testid="work-item-labels-input"]' }

  it 'successfully assigns a label' do
    find(labels_input_selector).fill_in(with: label.title)
    wait_for_requests
    # submit and simulate blur to save
    send_keys(:enter)
    find(label_title_selector).click
    wait_for_requests

    expect(work_item.labels).to include(label)
  end

  it 'successfully assigns multiple labels' do
    label2 = create(:label, project: project, title: "testing-label-2")

    find(labels_input_selector).fill_in(with: label.title)
    wait_for_requests
    send_keys(:enter)

    find(labels_input_selector).fill_in(with: label2.title)
    wait_for_requests
    send_keys(:enter)

    find(label_title_selector).click
    wait_for_requests

    expect(work_item.labels).to include(label)
    expect(work_item.labels).to include(label2)
  end

  it 'removes all labels on clear all button click' do
    find(labels_input_selector).fill_in(with: label.title)
    wait_for_requests
    send_keys(:enter)
    find(label_title_selector).click
    wait_for_requests

    expect(work_item.labels).to include(label)

    within(labels_input_selector) do
      find('input').click
      click_button 'Clear all'
    end
    find(label_title_selector).click
    wait_for_requests

    expect(work_item.labels).not_to include(label)
  end

  it 'removes label on clicking badge cross button' do
    find(labels_input_selector).fill_in(with: label.title)
    wait_for_requests
    send_keys(:enter)
    find(label_title_selector).click
    wait_for_requests

    expect(page).to have_text(label.title)

    within(labels_input_selector) do
      click_button 'Remove label'
    end
    find(label_title_selector).click
    wait_for_requests

    expect(work_item.labels).not_to include(label)
  end

  it 'updates the labels in real-time' do
    Capybara::Session.new(:other_session)

    using_session :other_session do
      visit work_items_path
      expect(page).not_to have_text(label.title)
    end

    find(labels_input_selector).fill_in(with: label.title)
    wait_for_requests
    send_keys(:enter)
    find(label_title_selector).click
    wait_for_requests

    expect(page).to have_text(label.title)

    using_session :other_session do
      wait_for_requests
      expect(page).to have_text(label.title)
    end
  end
end

RSpec.shared_examples 'work items description' do
  it 'shows GFM autocomplete', :aggregate_failures do
    click_button "Edit description"
    fill_in _('Description'), with: "@#{user.username}"

    page.within('.atwho-container') do
      expect(page).to have_text(user.name)
    end
  end

  it 'autocompletes available quick actions', :aggregate_failures do
    click_button "Edit description"
    fill_in _('Description'), with: '/'

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

      ::WorkItems::UpdateService.new(
        container: work_item.project,
        current_user: other_user,
        params: { description: "oh no!" }
      ).execute(work_item)

      wait_for_requests

      fill_in _('Description'), with: 'oh yeah!'

      expect(page).to have_text(expected_warning)

      click_button s_('WorkItem|Save and overwrite')

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
      expect(page).to have_text("You're inviting members to the #{work_item.project.name} project")
    end
  end
end

RSpec.shared_examples 'work items milestone' do
  it 'searches and sets or removes milestone for the work item' do
    click_button s_('WorkItem|Add to milestone')
    send_keys "\"#{milestone.title}\""
    select_listbox_item(milestone.title, exact_text: true)

    expect(page).to have_button(milestone.title)

    click_button milestone.title
    select_listbox_item(s_('WorkItem|No milestone'), exact_text: true)

    expect(page).to have_button(s_('WorkItem|Add to milestone'))
  end
end

RSpec.shared_examples 'work items comment actions for guest users' do
  context 'for guest user' do
    it 'hides other actions other than copy link' do
      page.within(".main-notes-list") do
        click_button _('More actions'), match: :first

        expect(page).to have_button _('Copy link')
        expect(page).not_to have_button _('Assign to commenting user')
      end
    end
  end
end

RSpec.shared_examples 'work items notifications' do
  it 'displays toast when notification is toggled' do
    click_button _('More actions'), match: :first

    within_testid('notifications-toggle-form') do
      expect(page).not_to have_button(class: 'gl-toggle is-checked')

      click_button(class: 'gl-toggle')

      expect(page).to have_button(class: 'gl-toggle is-checked')
    end

    expect(page).to have_css('.gl-toast', text: _('Notifications turned on.'))
  end
end

RSpec.shared_examples 'work items todos' do
  it 'adds item to the list' do
    expect(page).to have_button s_('WorkItem|Add a to do')

    click_button s_('WorkItem|Add a to do')

    expect(page).to have_button s_('WorkItem|Mark as done')

    within_testid('todos-shortcut-button') do
      expect(page).to have_content '1'
    end
  end

  it 'marks a todo as done' do
    click_button s_('WorkItem|Add a to do')
    click_button s_('WorkItem|Mark as done')

    expect(page).to have_button s_('WorkItem|Add a to do')
    within_testid('todos-shortcut-button') do
      expect(page).to have_content("")
    end
  end
end

RSpec.shared_examples 'work items award emoji' do
  let(:award_section_selector) { '.awards' }
  let(:award_button_selector) { '[data-testid="award-button"]' }
  let(:selected_award_button_selector) { '[data-testid="award-button"].selected' }
  let(:grinning_emoji_selector) { 'gl-emoji[data-name="grinning"]' }
  let(:tooltip_selector) { '.gl-tooltip' }

  def select_emoji
    page.within(award_section_selector) do
      page.first(award_button_selector).click
    end

    wait_for_requests
  end

  before do
    emoji_upvote
  end

  it 'adds award to the work item for current user' do
    select_emoji

    within(award_section_selector) do
      expect(page).to have_selector(selected_award_button_selector)

      # As the user2 has already awarded the `:thumbsup:` emoji, the emoji count will be 2
      expect(first(award_button_selector)).to have_content '2'
    end
    expect(page.find(tooltip_selector)).to have_content("You and John reacted with :thumbsup:")
  end

  it 'removes award from work item for current user' do
    select_emoji

    page.within(award_section_selector) do
      # As the user2 has already awarded the `:thumbsup:` emoji, the emoji count will be 2
      expect(first(award_button_selector)).to have_content '2'
    end

    select_emoji

    page.within(award_section_selector) do
      # The emoji count will be back to 1
      expect(first(award_button_selector)).to have_content '1'
    end
  end

  it 'add custom award to the work item for current user' do
    within(award_section_selector) do
      click_button _('Add reaction')
      find(grinning_emoji_selector).click

      expect(page).to have_selector(grinning_emoji_selector)
    end
  end
end

RSpec.shared_examples 'work items parent' do |type|
  let(:work_item_parent) { create(:work_item, type, project: project) }

  def set_parent(parent_text)
    find('[data-testid="listbox-search-input"] .gl-listbox-search-input',
      visible: true).send_keys "\"#{parent_text}\""
    wait_for_requests

    find('.gl-new-dropdown-item', text: parent_text).click
    wait_for_all_requests
  end

  it 'searches and sets or removes parent for the work item' do
    find_by_testid('edit-parent').click
    within_testid('work-item-parent-form') do
      set_parent(work_item_parent.title)
    end

    expect(find_by_testid('work-item-parent-link')).to have_text(work_item_parent.title)
    wait_for_requests

    page.refresh
    find_by_testid('edit-parent').click

    click_button('Unassign')
    wait_for_requests

    expect(find_by_testid('work-item-parent-none')).to have_text('None')
  end
end
