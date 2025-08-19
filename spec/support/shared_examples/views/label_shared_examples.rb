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

RSpec.shared_examples 'archiving label' do
  it 'archives label' do
    expect(label.archived).to be_falsey

    check 'label_archived'
    click_button 'Save changes'

    expect(label.reload.archived).to be_truthy
  end
end
