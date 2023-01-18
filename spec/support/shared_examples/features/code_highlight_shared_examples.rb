# frozen_string_literal: true

RSpec.shared_examples 'code highlight' do
  include PreferencesHelper

  let_it_be(:current_user) { user }
  let_it_be(:scheme_class) { user_color_scheme }

  it 'has highlighted code', :js do
    wait_for_requests
    expect(subject).to have_selector(".js-syntax-highlight.#{scheme_class}")
  end
end
