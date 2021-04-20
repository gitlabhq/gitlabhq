# frozen_string_literal: true

RSpec.shared_examples 'a creatable merge request' do
  include WaitForRequests

  it 'creates new merge request', :js do
    find('.js-assignee-search').click
    page.within '.dropdown-menu-user' do
      click_link user2.name
    end

    expect(find('input[name="merge_request[assignee_ids][]"]', visible: false).value).to match(user2.id.to_s)
    page.within '.js-assignee-search' do
      expect(page).to have_content user2.name
    end

    click_link 'Assign to me'

    expect(find('input[name="merge_request[assignee_ids][]"]', visible: false).value).to match(user.id.to_s)
    page.within '.js-assignee-search' do
      expect(page).to have_content user.name
    end

    click_button 'Milestone'
    page.within '.issue-milestone' do
      click_link milestone.title
    end

    expect(find('input[name="merge_request[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)
    page.within '.js-milestone-select' do
      expect(page).to have_content milestone.title
    end

    click_button 'Labels'
    page.within '.dropdown-menu-labels' do
      click_link label.title
      click_link label2.title
    end

    page.within '.js-label-select' do
      expect(page).to have_content label.title
    end
    expect(page.all('input[name="merge_request[label_ids][]"]', visible: false)[1].value).to match(label.id.to_s)
    expect(page.all('input[name="merge_request[label_ids][]"]', visible: false)[2].value).to match(label2.id.to_s)

    click_button 'Create merge request'

    page.within '.issuable-sidebar' do
      page.within '.assignee' do
        expect(page).to have_content user.name
      end

      page.within '.milestone' do
        expect(page).to have_content milestone.title
      end

      page.within '.labels' do
        expect(page).to have_content label.title
        expect(page).to have_content label2.title
      end
    end
  end

  it 'updates the branches when selecting a new target project', :js do
    target_project_member = target_project.owner
    ::Branches::CreateService.new(target_project, target_project_member)
      .execute('a-brand-new-branch-to-test', 'master')

    visit project_new_merge_request_path(source_project)

    first('.js-target-project').click
    find('.dropdown-target-project .dropdown-content a', text: target_project.full_path).click

    wait_for_requests

    first('.js-target-branch').click

    within('.js-target-branch-dropdown .dropdown-content') do
      expect(page).to have_content('a-brand-new-branch-to-test')
    end
  end
end
