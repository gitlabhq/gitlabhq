# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/_home_panel' do
  let(:group) { create(:group) }

  before do
    assign(:group, group)
  end

  it 'renders the group ID' do
    render

    expect(rendered).to have_content("Group ID: #{group.id}")
  end
end
