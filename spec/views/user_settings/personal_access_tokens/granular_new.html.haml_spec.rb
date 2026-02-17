# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user_settings/personal_access_tokens/granular_new.html.haml', feature_category: :system_access do
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- we need these objects to be persisted
  let_it_be(:user) { create(:user) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  before do
    sign_in(user)
  end

  it 'shows the granular personal access token form' do
    render

    expect(rendered).to have_selector('div#js-create-granular-token-app')
  end
end
