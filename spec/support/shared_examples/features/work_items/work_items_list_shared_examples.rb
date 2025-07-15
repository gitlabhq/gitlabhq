# frozen_string_literal: true

RSpec.shared_examples 'no work items in the list' do
  it 'shows message when there are no items in the list' do
    expect(page).to have_content("No results found")
  end
end

RSpec.shared_examples 'shows open items in the list' do
  it 'loads the open items' do
    within('.issuable-list') do
      expect(page).to have_link(open_item.title)
        .and have_no_link(closed_item.title)
    end
  end
end

RSpec.shared_examples 'shows closed items in the list' do
  it 'load the closed items' do
    within('.issuable-list') do
      expect(page).to have_no_link(open_item.title)
        .and have_link(closed_item.title)
    end
  end
end

RSpec.shared_examples 'shows all items in the list' do
  it 'load all the items' do
    within('.issuable-list') do
      expect(page).to have_link(open_item.title)
        .and have_link(closed_item.title)
    end
  end
end

RSpec.shared_examples 'do not shows items in the list' do
  it 'load all the items' do
    within('.issuable-list') do
      expect(page).to have_no_link(open_item.title)
        .and have_no_link(closed_item.title)
    end
  end
end

RSpec.shared_examples 'dates on the work items list' do |date|
  it 'renders the date' do
    expect(find_by_testid('issuable-due-date-title').text).to have_text(date)
  end
end

RSpec.shared_examples 'pagination on the work items list page' do
  it 'displays default page size of 20 items with correct dropdown text' do
    expect(page).to have_selector(issuable_container, count: 20)

    expect(page).to have_button _('Show 20 items')

    expect(page).to have_button _('Next')
    expect(page).to have_button _('Previous'), disabled: true
  end

  it 'navigates through pages using Next and Previous buttons' do
    expect(page).to have_button _('Previous'), disabled: true
    expect(page).to have_button _('Next'), disabled: false

    click_button _('Next')

    expect(page).to have_button _('Previous'), disabled: false
    expect(page).to have_button _('Next'), disabled: true

    expect(page).to have_selector(issuable_container, count: 5)

    click_button _('Previous')

    expect(page).to have_button _('Previous'), disabled: true
    expect(page).to have_button _('Next'), disabled: false
    expect(page).to have_selector(issuable_container, count: 20)
  end

  it 'changes page size and updates display accordingly' do
    click_button _('Show 20 items')

    within_testid('list-footer') do
      find('[role="option"]', text: _('Show 50 items')).click
    end

    expect(page).to have_selector(issuable_container, count: 25)

    expect(page).not_to have_button _('Next'), disabled: true
    expect(page).not_to have_button _('Previous'), disabled: true
  end
end
