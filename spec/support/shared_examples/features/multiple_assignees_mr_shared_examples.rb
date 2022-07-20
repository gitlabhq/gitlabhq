# frozen_string_literal: true

RSpec.shared_examples 'multiple assignees merge request' do |action, save_button_title|
  it "#{action} a MR with multiple assignees", :js do
    find('.js-assignee-search').click
    page.within '.dropdown-menu-user' do
      click_link user.name
      click_link user2.name
    end

    # Extra click needed in order to toggle the dropdown
    find('.js-assignee-search').click

    expect(all('input[name="merge_request[assignee_ids][]"]', visible: false).map(&:value))
      .to match_array([user.id.to_s, user2.id.to_s])

    page.within '.js-assignee-search' do
      expect(page).to have_content "#{user2.name} + 1 more"
    end

    click_button save_button_title

    page.within '.issuable-sidebar' do
      page.within '.assignee' do
        expect(page).to have_content '2 Assignees'

        click_link 'Edit'

        expect(page).to have_content user.name
        expect(page).to have_content user2.name
      end
    end

    page.within '.dropdown-menu-user' do
      click_link user.name
    end

    page.within '.issuable-sidebar' do
      page.within '.assignee' do
        # Closing dropdown to persist
        click_link 'Apply'

        expect(page).to have_content user2.name
      end
    end
  end
end
