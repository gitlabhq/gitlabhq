# frozen_string_literal: true

RSpec.shared_examples 'multiple assignees widget merge request' do |action, save_button_title|
  it "#{action} a MR with multiple assignees", :js do
    find('.js-assignee-search').click
    page.within '.dropdown-menu-user' do
      click_link user.name
      click_link user2.name
    end

    find('.dropdown-menu-close-icon').click

    expect(all('input[name="merge_request[assignee_ids][]"]', visible: false).map(&:value))
      .to match_array([user.id.to_s, user2.id.to_s])

    page.within '.js-assignee-search' do
      expect(page).to have_content "#{user2.name} + 1 more"
    end

    click_button save_button_title

    page.within '.issuable-sidebar .assignee' do
      expect(page).to have_content '2 Assignees'

      click_button('Edit')

      within_testid('base-dropdown-menu') do
        expect(page).to have_content user.name
        expect(page).to have_content user2.name

        find_by_testid("listbox-item-#{user.username}").click
      end

      # Closing the dropdown persists the assignees
      click_button('Edit')

      expect(page).to have_content user2.name
      expect(page).to have_no_content user.name
    end
  end
end
