# frozen_string_literal: true

RSpec.shared_context 'with work_items_beta' do |flag|
  before do
    stub_feature_flags(work_items_beta: flag)
    stub_feature_flags(notifications_todos_buttons: false)

    page.refresh
    wait_for_all_requests
  end
end

RSpec.shared_examples 'work items title' do
  it 'updates title' do
    click_button 'Edit', match: :first
    fill_in 'Title (required)', with: 'Work item title'
    send_keys([:command, :enter])

    expect(page).to have_css('h1', text: 'Work item title')
  end
end

RSpec.shared_examples 'work items toggle status button' do
  it 'updates status', :aggregate_failures do
    within_testid 'work-item-comment-form-actions' do
      # Depending of the context, the button's text could be `Close issue`, `Close key result`, `Close objective`, etc.
      click_button 'Close', match: :first
    end

    expect(page).to have_button 'Reopen'
    expect(page).to have_css('.gl-badge', text: 'Closed')
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

    it 'shows work item note actions', :aggregate_failures do
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

  it 'successfully posts comments using shortcut only once' do
    expected_matches = find('ul.main-notes-list').all('li').size + 1
    set_comment
    send_keys([modifier_key, :enter], [modifier_key, :enter], [modifier_key, :enter])

    expect(find('ul.main-notes-list')).to have_selector('li', count: expected_matches)
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
  it 'assigns and unassigns user', :aggregate_failures do
    within_testid 'work-item-assignees' do
      click_button 'Edit'
      select_listbox_item(user.username)
      send_keys :escape

      expect(page).to have_link(user.name)

      click_button 'Edit'
      click_button 'Clear'

      expect(page).not_to have_link(user.name)
    end
  end

  it 'updates the assignee in real-time', :aggregate_failures do
    using_session :other_session do
      visit work_items_path

      expect(page).not_to have_link(user.name)
    end

    click_button 'assign yourself'

    expect(page).to have_link(user.name)
    using_session :other_session do
      expect(page).to have_link(user.name)
    end
  end
end

RSpec.shared_examples 'work items labels' do
  it 'shows a label with a link pointing to filtered work items list' do
    within_testid 'work-item-labels' do
      expect(page).to have_link(label.title, href: "#{project_issues_path(project)}?label_name[]=#{label.title}")
    end
  end

  it 'adds and removes a label', :aggregate_failures do
    within_testid 'work-item-labels' do
      expect(page).not_to have_css '.gl-label', text: label2.title

      click_button 'Edit'
      select_listbox_item(label2.title)
      click_button 'Apply'

      expect(page).to have_css '.gl-label', text: label2.title

      click_button 'Edit'
      click_button 'Clear'

      expect(page).not_to have_css '.gl-label', text: label2.title
    end
  end

  it 'updates the assigned labels in real-time', :aggregate_failures do
    using_session :other_session do
      visit work_items_path

      expect(page).not_to have_css '.gl-label', text: label2.title
    end

    within_testid 'work-item-labels' do
      click_button 'Edit'
      select_listbox_item(label2.title)
      click_button 'Apply'

      expect(page).to have_css '.gl-label', text: label2.title
    end

    expect(page).to have_css '.gl-label', text: label2.title
    using_session :other_session do
      expect(page).to have_css '.gl-label', text: label2.title
    end
  end

  it 'creates, auto-selects, and adds new label' do
    within_testid 'work-item-labels' do
      click_button 'Edit'
      click_button 'Create project label'
      send_keys 'Quintessence'
      click_button 'Create'
      click_button 'Apply'

      expect(page).to have_css '.gl-label', text: 'Quintessence'
    end
  end
end

RSpec.shared_examples 'work items description' do
  it 'shows GLFM autocomplete' do
    click_button 'Edit', match: :first
    fill_in _('Description'), with: "@#{user.username}"

    page.within('.atwho-container') do
      expect(page).to have_text(user.name)
    end
  end

  it 'autocompletes available quick actions', :aggregate_failures do
    click_button 'Edit', match: :first
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
      stub_feature_flags(notifications_todos_buttons: false)
    end

    it 'shows conflict message when description changes', :aggregate_failures do
      click_button 'Edit', match: :first

      ::WorkItems::UpdateService.new(
        container: work_item.project,
        current_user: other_user,
        params: { description: "oh no!" }
      ).execute(work_item)

      wait_for_requests

      fill_in _('Description'), with: 'oh yeah!'

      expect(page).to have_text(expected_warning)

      page.find('summary', text: 'View current version').click
      expect(find_by_testid('conflicted-description').value).to eq('oh no!')

      click_button s_('WorkItem|Save and overwrite')

      within_testid 'work-item-description' do
        expect(page).to have_text("oh yeah!")
      end
    end
  end
end

RSpec.shared_examples 'work items invite members' do
  include Features::InviteMembersModalHelpers

  it 'shows modal to invite members' do
    within_testid 'work-item-assignees' do
      click_button 'Edit'
      click_link('Invite members')
    end

    page.within invite_modal_selector do
      expect(page).to have_text("You're inviting members to the #{work_item.project.name} project")
    end
  end
end

RSpec.shared_examples 'work items milestone' do
  let(:work_item_milestone_selector) { '[data-testid="work-item-milestone"]' }

  it 'passes axe automated accessibility testing in closed state' do
    expect(page).to be_axe_clean.within(work_item_milestone_selector)
  end

  it 'passes axe automated accessibility testing in open state' do
    within(work_item_milestone_selector) do
      click_button _('Edit')

      expect(page).to be_axe_clean.within(work_item_milestone_selector)
    end
  end

  it 'adds and removes milestone', :aggregate_failures do
    within_testid 'work-item-milestone' do
      click_button 'Edit'
      send_keys "\"#{milestones[11].title}\""
      select_listbox_item(milestones[11].title)

      expect(page).to have_link(milestones[11].title)

      click_button 'Edit'
      click_button 'Clear'

      expect(page).to have_text('None')
      expect(page).not_to have_link(milestones[11].title)
    end
  end
end

RSpec.shared_examples 'work items comment actions for guest users' do
  context 'for guest user' do
    it 'hides other actions other than copy link', :aggregate_failures do
      page.within(".main-notes-list") do
        click_button _('More actions'), match: :first

        expect(page).to have_button _('Copy link')
        expect(page).not_to have_button _('Assign to commenting user')
      end
    end
  end
end

RSpec.shared_examples 'work items notifications' do
  it 'displays toast when notification is toggled', :aggregate_failures do
    click_button _('More actions'), match: :first

    within_testid 'notifications-toggle-form' do
      expect(page).not_to have_css('.gl-toggle.is-checked')

      click_button(class: 'gl-toggle')

      expect(page).to have_css('.gl-toggle.is-checked')
    end

    expect(page).to have_css('.gl-toast', text: _('Notifications turned on.'))
  end
end

RSpec.shared_examples 'work items lock discussion' do
  it 'locks and unlocks discussion', :aggregate_failures do
    click_button _('More actions'), match: :first
    click_button 'Lock discussion'
    click_button _('More actions'), match: :first # click again to close the dropdown

    expect(page).to have_text 'The discussion in this issue is locked. Only project members can comment.'

    click_button _('More actions'), match: :first
    click_button 'Unlock discussion'

    expect(page).not_to have_text 'The discussion in this issue is locked. Only project members can comment.'
  end
end

RSpec.shared_examples 'work items confidentiality' do
  it 'turns on and off confidentiality', :aggregate_failures do
    click_button _('More actions'), match: :first
    click_button 'Turn on confidentiality'

    expect(page).to have_css('.gl-badge', text: 'Confidential')

    click_button _('More actions'), match: :first
    click_button 'Turn off confidentiality'

    expect(page).not_to have_css('.gl-badge', text: 'Confidential')
  end
end

RSpec.shared_examples 'work items todos' do
  it 'adds item to to-do list', :aggregate_failures do
    expect(page).to have_button s_('WorkItem|Add a to-do item')

    click_button s_('WorkItem|Add a to-do item')

    expect(page).to have_button s_('WorkItem|Mark as done')

    within_testid 'todos-shortcut-button' do
      expect(page).to have_content '1'
    end
  end

  it 'marks to-do item as done', :aggregate_failures do
    click_button s_('WorkItem|Add a to-do item')
    click_button s_('WorkItem|Mark as done')

    expect(page).to have_button s_('WorkItem|Add a to-do item')
    within_testid 'todos-shortcut-button' do
      expect(page).to have_content("")
    end
  end
end

RSpec.shared_examples 'work items award emoji' do
  before do
    emoji_upvote
  end

  it 'adds and removes award and custom award', :aggregate_failures do
    # user2 has already awarded the `:thumbsup:` emoji
    expect(page).to have_button '👍 1'

    click_button '👍'

    expect(page).to have_button '👍 2'
    expect(page).to have_css('.gl-tooltip', text: "John and you reacted with :#{AwardEmoji::THUMBS_UP}:")

    click_button '👍'

    expect(page).to have_button '👍 1'
    expect(page).to have_css('.gl-tooltip', text: "John reacted with :#{AwardEmoji::THUMBS_UP}:")

    click_button _('Add reaction'), match: :first
    click_button '😀'

    expect(page).to have_button '😀 1'
  end
end

RSpec.shared_examples 'work items parent' do |type|
  let(:work_item_parent) { create(:work_item, type, project: project) }

  it 'adds and removes parent', :aggregate_failures do
    within_testid 'work-item-parent' do
      click_button 'Edit'
      send_keys(work_item_parent.title)
      select_listbox_item(work_item_parent.title)

      expect(page).to have_link(work_item_parent.title)

      page.refresh

      click_button 'Edit'
      click_button 'Clear'

      expect(page).to have_content 'None'
      expect(page).not_to have_link(work_item_parent.title)
    end
  end
end

def find_and_click_edit(selector)
  within(selector) do
    click_button 'Edit'
  end
end

def find_and_click_clear(selector, button_name = 'Clear')
  within(selector) do
    click_button button_name
  end
end

RSpec.shared_examples 'work items iteration' do
  include Features::IterationHelpers
  let(:work_item_iteration_selector) { '[data-testid="work-item-iteration"]' }
  let_it_be(:iteration_cadence) { create(:iterations_cadence, group: group, active: true) }
  let_it_be(:iteration) do
    create(
      :iteration,
      iterations_cadence: iteration_cadence,
      group: group,
      start_date: 1.day.from_now,
      due_date: 2.days.from_now
    )
  end

  let_it_be(:iteration2) do
    create(
      :iteration,
      iterations_cadence: iteration_cadence,
      group: group,
      start_date: 2.days.ago,
      due_date: 1.day.ago,
      state: 'closed',
      skip_future_date_validation: true
    )
  end

  it 'passes axe automated accessibility testing in closed state' do
    expect(page).to be_axe_clean.within(work_item_iteration_selector)
  end

  it 'passes axe automated accessibility testing in open state' do
    within(work_item_iteration_selector) do
      click_button _('Edit')
      wait_for_requests

      expect(page).to be_axe_clean.within(work_item_iteration_selector)
    end
  end

  it 'adds and removes an iteration', :aggregate_failures do
    within_testid 'work-item-iteration' do
      click_button 'Edit'
      send_keys(iteration.title)
      select_listbox_item(iteration.period)

      expect(page).to have_text(iteration_cadence.title)
      expect(page).to have_text(iteration_period_display(iteration))

      click_button 'Edit'
      click_button 'Clear'

      expect(page).to have_content('None')
      expect(page).not_to have_text(iteration_cadence.title)
      expect(page).not_to have_text(iteration_period_display(iteration))
    end
  end
end

RSpec.shared_examples 'work items time tracking' do
  it 'passes axe automated accessibility testing for estimate and time spent modals', :aggregate_failures do
    click_button 'estimate'

    expect(page).to be_axe_clean.within('[role="dialog"]')

    within_testid 'set-time-estimate-modal' do
      click_button 'Close'
    end
    click_button 'time spent'

    expect(page).to be_axe_clean.within('[role="dialog"]')
  end

  it 'adds and removes an estimate', :aggregate_failures do
    click_button 'estimate'
    within_testid 'set-time-estimate-modal' do
      fill_in 'Estimate', with: '5d'
      click_button 'Save'
    end

    expect(page).to have_text 'Estimate 5d'
    expect(page).to have_button '5d'
    expect(page).not_to have_button 'estimate'

    click_button '5d'
    within_testid 'set-time-estimate-modal' do
      click_button 'Remove'
    end

    expect(page).not_to have_text 'Estimate 5d'
    expect(page).not_to have_button '5d'
    expect(page).to have_button 'estimate'
  end

  it 'adds and deletes time entries and view report', :aggregate_failures do
    click_button 'Add time entry'

    within_testid 'create-timelog-modal' do
      fill_in 'Time spent', with: '1d'
      fill_in 'Summary', with: 'First summary'
      click_button 'Save'
    end

    click_button 'Add time entry'

    within_testid 'create-timelog-modal' do
      fill_in 'Time spent', with: '2d'
      fill_in 'Summary', with: 'Second summary'
      click_button 'Save'
    end

    expect(page).to have_text 'Spent 3d'
    expect(page).to have_button '3d'

    click_button '3d'

    within_testid 'time-tracking-report-modal' do
      expect(page).to have_css 'h2', text: 'Time tracking report'
      expect(page).to have_text "1d #{user.name} First summary"
      expect(page).to have_text "2d #{user.name} Second summary"

      click_button 'Delete time spent', match: :first

      expect(page).to have_text "1d #{user.name} First summary"
      expect(page).not_to have_text "2d #{user.name} Second summary"

      click_button 'Close'
    end

    expect(page).to have_text 'Spent 1d'
    expect(page).to have_button '1d'
  end
end

RSpec.shared_examples 'work items crm contacts' do
  it 'searches for, adds and removes a contact', :aggregate_failures do
    within_testid 'work-item-crm-contacts' do
      click_button 'Edit'
      send_keys(contact.first_name)
      select_listbox_item(contact_name)
      send_keys(:escape)

      expect(page).to have_link contact_name

      click_button 'Edit'
      click_button 'Clear'

      expect(page).not_to have_link contact_name
    end
  end

  it 'passes axe automated accessibility testing' do
    within_testid 'work-item-crm-contacts' do
      click_button _('Edit')
      wait_for_requests

      expect(page).to be_axe_clean.within('[data-testid="work-item-crm-contacts"]')
    end
  end
end
