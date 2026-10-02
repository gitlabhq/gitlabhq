# frozen_string_literal: true

RSpec.shared_examples 'correct pagination' do
  it 'paginates correctly to page 3 and back' do
    page1_item_text = current_item_text
    click_next_page(next_button_selector)

    page2_item_text = current_item_text(previous: page1_item_text)
    click_next_page(next_button_selector)

    page3_item_text = current_item_text(previous: page2_item_text)
    click_prev_page(prev_button_selector)

    expect(current_item_text(previous: page3_item_text)).to eql(page2_item_text)

    click_prev_page(prev_button_selector)

    expect(current_item_text(previous: page2_item_text)).to eql(page1_item_text)
  end

  def click_next_page(next_button_selector)
    page.find(next_button_selector).click
  end

  def click_prev_page(prev_button_selector)
    page.find(prev_button_selector).click
  end

  # Wait for the previous page's item to leave the list before reading, so the
  # read cannot race the re-render that follows a page change.
  def current_item_text(previous: nil)
    expect(page).to have_no_selector(item_selector, exact_text: previous) if previous
    expect(page).to have_selector(item_selector, count: per_page)

    page.find(item_selector).text
  end
end
