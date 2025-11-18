# frozen_string_literal: true

RSpec.shared_examples 'handles archived labels in view' do
  it 'shows no archived labels message' do
    click_archived_tab

    page.within('.labels-container') do
      expect(page).not_to have_content label.title
      expect(page).to have_content('No archived labels')
    end
  end

  context 'with archived label' do
    before do
      label.update!(archived: true)
    end

    it 'shows archived label' do
      click_archived_tab

      page.within('.labels-container') do
        expect(page).to have_content label.title
      end
    end
  end

  def click_archived_tab
    page.within('.gl-tabs-nav') do
      click_link 'Archived'
    end
  end
end

RSpec.shared_examples 'unarchiving label' do
  it 'shows unarchive alert for archived label' do
    expect(page).to have_content('This label is archived and not available for use. Unarchive to use it again.')
    expect(page).to have_button('Unarchive label')
  end

  it 'unarchives label when clicking unarchive button' do
    expect(label.archived).to be_truthy

    click_button 'Unarchive label'

    expect(label.reload.archived).to be_falsey
    expect(page).not_to have_content('This label is archived and not available for use. Unarchive to use it again.')
    expect(page).not_to have_button('Unarchive label')
  end
end
