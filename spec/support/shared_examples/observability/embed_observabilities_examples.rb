# frozen_string_literal: true

RSpec.shared_examples 'embeds observability' do
  it 'renders iframe in description' do
    page.within('.description') do
      expect_observability_iframe(page.html)
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
      expect_observability_iframe(page.html)
    end
  end
end

RSpec.shared_examples 'does not embed observability' do
  it 'does not render iframe in description' do
    page.within('.description') do
      expect_observability_iframe(page.html, to_be_nil: true)
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
      expect_observability_iframe(page.html, to_be_nil: true)
    end
  end
end

def expect_observability_iframe(html, to_be_nil: false)
  iframe = Nokogiri::HTML.parse(html).at_css('#observability-ui-iframe')

  expect(html).to include(observable_url)

  if to_be_nil
    expect(iframe).to be_nil
  else
    expect(iframe).not_to be_nil
    iframe_src = "#{expected_observable_url}&theme=light&username=#{user.username}&kiosk=inline-embed"
    expect(iframe.attributes['src'].value).to eq(iframe_src)
  end
end
