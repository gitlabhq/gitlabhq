# frozen_string_literal: true

RSpec.shared_examples 'no work items in the list' do
  it 'shows message when there are no items in the list' do
    expect(page).to have_content("Track bugs, plan features, and organize your efforts with work items")
  end
end

RSpec.shared_examples 'no work items in search results' do
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

RSpec.shared_examples 'parent filter' do
  it 'filters the child item by parent' do
    select_tokens 'Parent', '=', parent_item.title, submit: true

    expect(page).to have_selector(issuable_container, count: 1)
    expect(page).to have_link(child_item.title)
  end

  it 'filters the child item by not a parent' do
    select_tokens 'Parent', '!=', parent_item.title, submit: true

    expect(page).to have_selector(issuable_container, count: 2)
    expect(page).not_to have_link(child_item.title)
    expect(page).to have_link(work_item_2.title)
  end

  it 'filters the child items by Any wild card' do
    select_tokens 'Parent', '=', 'Any', submit: true

    expect(page).to have_selector(issuable_container, count: 1)
    expect(page).to have_link(child_item.title)
  end

  it 'filters the child items by None' do
    select_tokens 'Parent', '=', 'None', submit: true

    expect(page).to have_selector(issuable_container, count: 2)
    expect(page).to have_link(parent_item.title)
    expect(page).to have_link(work_item_2.title)
    expect(page).not_to have_link(child_item.title)
  end

  it 'shows parent in the filtered search dropdown' do
    select_tokens 'Parent', '='

    # "None", "Any", "Epic without parent", "Child epic" and "Parent epic"
    expect_suggestion_count expected_count
  end
end
