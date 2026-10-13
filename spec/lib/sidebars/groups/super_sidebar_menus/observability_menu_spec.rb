# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu, feature_category: :observability do
  subject(:observability_menu) { described_class.new({}) }

  it 'has title and sprite_icon' do
    expect(observability_menu.title).to eq(s_('Navigation|Observe'))
    expect(observability_menu.sprite_icon).to eq('eye')
  end
end
