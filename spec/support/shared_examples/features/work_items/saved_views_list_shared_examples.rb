# frozen_string_literal: true

RSpec.shared_examples 'saved view creation from add view dropdown' do
  it 'creates a private saved view with title and description and verifies data in edit modal' do
    open_new_view_modal_from_dropdown

    fill_in 'saved-view-title', with: 'My private view'
    fill_in 'saved-view-description', with: 'A view for tracking bugs'
    click_button 'Create view'
    wait_for_requests

    expect(page).to have_button('My private view')

    open_edit_modal_from_saved_view_tab('My private view')

    expect(find_field('saved-view-title').value).to eq('My private view')
    expect(find_field('saved-view-description').value).to eq('A view for tracking bugs')
    within_testid('saved-view-visibility') do
      expect(find('input[type="radio"][value="private"]')).to be_checked
    end
  end

  it 'creates a shared saved view and verifies data in edit modal' do
    open_new_view_modal_from_dropdown

    fill_in 'saved-view-title', with: 'Shared team view'
    within_testid('saved-view-visibility') do
      find('input[type="radio"][value="shared"]').click
    end
    click_button 'Create view'
    wait_for_requests

    expect(page).to have_button('Shared team view')

    open_edit_modal_from_saved_view_tab('Shared team view')

    expect(find_field('saved-view-title').value).to eq('Shared team view')
    within_testid('saved-view-visibility') do
      expect(find('input[type="radio"][value="shared"]')).to be_checked
    end
  end

  it 'shows validation error when title is empty' do
    open_new_view_modal_from_dropdown

    click_button 'Create view'
    wait_for_requests

    expect(page).to have_content('Title is required.')
  end
end

RSpec.shared_examples 'saved view creation via save view button with filters' do
  it 'shows save view button when filters are changed' do
    select_tokens 'Label', '=', label.title, submit: true
    wait_for_requests

    expect(page).to have_testid('save-view-button')
  end

  it 'creates a saved view preserving the current filter' do
    select_tokens 'Label', '=', label.title, submit: true
    wait_for_requests

    find_by_testid('save-view-button').click
    wait_for_requests

    fill_in 'saved-view-title', with: 'Bug filter view'
    click_button 'Create view'
    wait_for_requests

    expect(page).to have_button('Bug filter view')
  end
end

RSpec.shared_examples 'guest user saved view restrictions' do
  it 'does not show the new view option in the add view dropdown' do
    find_by_testid('add-saved-view-fallback').click
    wait_for_requests

    expect(page).to have_content('Views')
    expect(page).not_to have_button('New view')
  end

  it 'does not show save view button when filters are changed' do
    select_tokens 'Label', '=', label.title, submit: true
    wait_for_requests

    expect(page).not_to have_testid('save-view-button')
  end
end
