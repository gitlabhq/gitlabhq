# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu, feature_category: :observability do
  subject(:observability_menu) { described_class.new({}) }

  let(:items) { observability_menu.instance_variable_get(:@items) }

  it 'has title and sprite_icon' do
    expect(observability_menu.title).to eq(s_('Navigation|Observability'))
    expect(observability_menu.sprite_icon).to eq('eye')
  end

  it 'defines list of NilMenuItem placeholders' do
    expect(items.map(&:class).uniq).to eq([Sidebars::NilMenuItem])
    expect(items.map(&:item_id)).to eq([
      :services,
      :traces_explorer,
      :logs_explorer,
      :metrics_explorer,
      :infrastructure_monitoring,
      :dashboard,
      :messaging_queues,
      :api_monitoring,
      :alerts,
      :exceptions,
      :service_map,
      :settings
    ])
  end
end
