# frozen_string_literal: true

RSpec.shared_examples 'code highlight' do
  include PreferencesHelper

  let_it_be(:current_user) { user }

  it 'has highlighted code', :js do
    wait_for_requests
    expect(subject).to have_selector(".js-syntax-highlight")
  end
end
