# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'registrations/welcome/show' do
  let_it_be(:user) { create(:user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:welcome_update_params).and_return({})

    render
  end

  subject { rendered }

  it { is_expected.not_to have_selector('label[for="user_setup_for_company"]') }
  it { is_expected.to have_button('Get started!') }
  it { is_expected.not_to have_selector('input[name="user[email_opted_in]"]') }
end
