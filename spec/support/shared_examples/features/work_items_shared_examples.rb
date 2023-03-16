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

RSpec.shared_examples 'work items comments' do
  let(:form_selector) { '[data-testid="work-item-add-comment"]' }

  it 'successfully creates and shows comments' do
    click_button 'Add a reply'

    find(form_selector).fill_in(with: "Test comment")
    click_button "Comment"

    wait_for_requests

    expect(page).to have_content "Test comment"
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

    page.within('.atwho-container') do
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
  include Spec::Support::Helpers::Features::InviteMembersModalHelper

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
