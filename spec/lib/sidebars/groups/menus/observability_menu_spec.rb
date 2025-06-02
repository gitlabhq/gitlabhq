# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::ObservabilityMenu, feature_category: :observability do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:group) { build_stubbed(:group, :private) }

  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }

  subject(:observability_menu) { described_class.new(context) }

  before_all do
    group.add_owner(user)
  end

  describe '#configure_menu_items' do
    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(observability_sass_features: group)
      end

      it 'adds all menu items' do
        expected_menu_items = [
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
        ]

        expect(observability_menu.renderable_items.map(&:item_id)).to match_array(expected_menu_items)
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(observability_sass_features: false)
      end

      it 'does not add any menu items' do
        expect(observability_menu.configure_menu_items).to be false
        expect(observability_menu.renderable_items).to be_empty
      end
    end
  end

  describe '#title, #sprite_icon, #link' do
    before do
      stub_feature_flags(observability_sass_features: group)
      observability_menu.configure_menu_items
    end

    it 'has the right title' do
      expect(observability_menu.title).to eq(_('Observability'))
    end

    it 'has the right sprite icon' do
      expect(observability_menu.sprite_icon).to eq('eye')
    end

    it 'has the right link' do
      expect(observability_menu.link).to eq(observability_menu.send(:services_menu_item).link)
    end
  end

  describe '#active_routes' do
    it 'has the right active routes' do
      expect(observability_menu.active_routes).to eq({ controller: 'groups/observability' })
    end
  end

  describe '#extra_container_html_options' do
    it 'has the right container options' do
      expect(observability_menu.extra_container_html_options).to eq({ class: 'shortcuts-observability' })
    end
  end

  describe '#serialize_as_menu_item_args' do
    it_behaves_like 'not serializable as super_sidebar_menu_args' do
      let(:menu) { described_class.new(context) }
    end
  end

  describe '#menu items links' do
    before do
      stub_feature_flags(observability_sass_features: group)
      observability_menu.configure_menu_items
    end

    it 'has the right links for each menu item' do
      menu_items = observability_menu.renderable_items

      expect(menu_items.find { |i| i.item_id == :services }.link).to include('services')
      expect(menu_items.find { |i| i.item_id == :traces_explorer }.link).to include('traces-explorer')
      expect(menu_items.find do |i|
        i.item_id == :logs_explorer
      end.link).to include(ERB::Util.url_encode('logs/logs-explorer'))
      expect(menu_items.find { |i| i.item_id == :metrics_explorer }.link).to include('metrics-explorer')
      expect(menu_items.find do |i|
        i.item_id == :infrastructure_monitoring
      end.link).to include('infrastructure-monitoring')
      expect(menu_items.find { |i| i.item_id == :dashboard }.link).to include('dashboard')
      expect(menu_items.find { |i| i.item_id == :messaging_queues }.link).to include('messaging-queues')
      expect(menu_items.find do |i|
        i.item_id == :api_monitoring
      end.link).to include(ERB::Util.url_encode('api-monitoring/explorer'))
      expect(menu_items.find { |i| i.item_id == :alerts }.link).to include('alerts')
      expect(menu_items.find { |i| i.item_id == :exceptions }.link).to include('exceptions')
      expect(menu_items.find { |i| i.item_id == :service_map }.link).to include('service-map')
    end
  end
end
