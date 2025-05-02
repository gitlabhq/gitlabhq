# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/_session_expire_modal', feature_category: :system_access do
  let(:user) { build_stubbed(:user) }

  before do
    allow(view).to receive_messages(current_user: user, session_expire_modal_data: { session_timeout: 5000 })
    stub_application_setting(session_expire_from_init: true)
  end

  it 'renders the modal' do
    render
    expect(rendered).to have_selector('#js-session-expire-modal')
  end
end
