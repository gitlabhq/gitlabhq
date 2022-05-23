# frozen_string_literal: true

RSpec.shared_examples 'correct pagination' do
  it 'paginates correctly to page 3 and back' do
    expect(page).to have_selector(item_selector, count: per_page)
    page1_item_text = page.find(item_selector).text
    click_next_page(next_button_selector)

    expect(page).to have_selector(item_selector, count: per_page)
    page2_item_text = page.find(item_selector).text
    click_next_page(next_button_selector)

    expect(page).to have_selector(item_selector, count: per_page)
    page3_item_text = page.find(item_selector).text
    click_prev_page(prev_button_selector)

    expect(page3_item_text).not_to eql(page2_item_text)
    expect(page.find(item_selector).text).to eql(page2_item_text)

    click_prev_page(prev_button_selector)

    expect(page.find(item_selector).text).to eql(page1_item_text)
    expect(page).to have_selector(item_selector, count: per_page)
  end

  def click_next_page(next_button_selector)
    page.find(next_button_selector).click
    wait_for_requests
  end

  def click_prev_page(prev_button_selector)
    page.find(prev_button_selector).click
    wait_for_requests
  end
end
