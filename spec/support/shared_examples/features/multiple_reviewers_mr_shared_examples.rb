# frozen_string_literal: true

RSpec.shared_examples 'multiple reviewers merge request' do |action, save_button_title|
  it "#{action} a MR with multiple reviewers", :js do
    find('.js-reviewer-search').click
    page.within '.dropdown-menu-user' do
      click_link user.name
      click_link user2.name
    end

    # Extra click needed in order to toggle the dropdown
    find('.js-reviewer-search').click

    expect(all('input[name="merge_request[reviewer_ids][]"]', visible: false).map(&:value))
      .to match_array([user.id.to_s, user2.id.to_s])

    page.within '.js-reviewer-search' do
      expect(page).to have_content "#{user2.name} + 1 more"
    end

    click_button save_button_title

    page.within '.issuable-sidebar' do
      page.within '.reviewer' do
        expect(page).to have_content '2 Reviewers'

        click_button 'Edit'

        expect(page).to have_content user.name
        expect(page).to have_content user2.name
      end
    end

    page.within '.reviewers-dropdown' do
      find_by_testid("listbox-item-#{user.username}").click
    end

    page.within '.issuable-sidebar' do
      page.within '.reviewer' do
        # Closing dropdown to persist
        click_button 'Edit'

        expect(page).to have_content user2.name
      end
    end
  end
end
