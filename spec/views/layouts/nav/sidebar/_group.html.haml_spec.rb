# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/sidebar/_group' do
  let(:group) { create(:group) }

  before do
    assign(:group, group)
  end

  it_behaves_like 'has nav sidebar'
end
