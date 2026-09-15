# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/profile', :with_current_organization do
  let(:user) { create(:user) }

  before do
    allow(view).to receive_messages(
      session: {},
      current_user: user,
      current_user_mode: Gitlab::Auth::CurrentUserMode.new(user),
      experiment_enabled?: false
    )
    allow(view).to receive(:enable_search_settings).and_call_original
  end

  it 'displays the search settings entry point' do
    render
    expect(rendered).to include('js-search-settings-app')
  end
end
