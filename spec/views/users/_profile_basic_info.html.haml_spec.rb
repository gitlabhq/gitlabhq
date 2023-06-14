# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'users/_profile_basic_info', feature_category: :user_profile do
  let_it_be(:template) { 'users/profile_basic_info' }
  let_it_be(:user) { build_stubbed(:user) }

  before do
    assign(:user, user)
  end

  it 'renders the join date' do
    user.created_at = Time.new(2020, 6, 21, 9, 22, 20, "UTC")

    render(template)

    expect(rendered).to include("Member since June 21, 2020")
    expect(rendered).not_to include("09:22")
  end
end
