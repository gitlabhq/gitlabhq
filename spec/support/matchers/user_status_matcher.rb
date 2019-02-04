# frozen_string_literal: true

RSpec::Matchers.define :show_user_status do |status|
  match do |page|
    expect(page).to have_selector(".user-status-emoji[title='#{status.message}']")

    # The same user status might be displayed multiple times on the page
    emoji_span = page.first(".user-status-emoji[title='#{status.message}']")
    page.within(emoji_span) do
      expect(page).to have_emoji(status.emoji)
    end
  end
end
