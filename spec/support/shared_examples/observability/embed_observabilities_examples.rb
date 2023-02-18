# frozen_string_literal: true

RSpec.shared_examples 'embeds observability' do
  it 'renders iframe in description' do
    page.within('.description') do
      expect(page.html).to include(expected)
    end
  end

  it 'renders iframe in comment' do
    expect(page).not_to have_css('.note-text')

    page.within('.js-main-target-form') do
      fill_in('note[note]', with: observable_url)
      click_button('Comment')
    end

    wait_for_requests

    page.within('.note-text') do
      expect(page.html).to include(expected)
    end
  end
end

RSpec.shared_examples 'does not embed observability' do
  it 'does not render iframe in description' do
    page.within('.description') do
      expect(page.html).not_to include(expected)
      expect(page.html).to include(observable_url)
    end
  end

  it 'does not render iframe in comment' do
    expect(page).not_to have_css('.note-text')

    page.within('.js-main-target-form') do
      fill_in('note[note]', with: observable_url)
      click_button('Comment')
    end

    wait_for_requests

    page.within('.note-text') do
      expect(page.html).not_to include(expected)
      expect(page.html).to include(observable_url)
    end
  end
end
