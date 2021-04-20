# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/sidebar/_profile' do
  let(:user) { create(:user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  it_behaves_like 'has nav sidebar'
  it_behaves_like 'sidebar includes snowplow attributes', 'render', 'user_side_navigation', 'user_side_navigation'
end
