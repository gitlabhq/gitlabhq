# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::ObservabilityMenu, feature_category: :observability do
  include StubMemberAccessLevel
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:group) { build_stubbed(:group, :private) }

  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }

  subject(:observability_menu) { described_class.new(context) }

  describe '#configure_menu_items' do
    context 'when observability_sass_features feature flag is enabled' do
      before do
        stub_feature_flags(observability_sass_features: group)
      end

      context 'when observability_group_o11y_setting is persisted' do
        before do
          stub_feature_flags(o11y_settings_access: false)
          stub_member_access_level(group, developer: user)
          allow(group).to receive(:observability_group_o11y_setting).and_return(instance_double(
            Observability::GroupO11ySetting, persisted?: true))
        end

        it 'adds all observability menu items' do
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
            :settings,
            :setup
          ]

          expect(observability_menu.renderable_items.map(&:item_id)).to match_array(expected_menu_items)
        end
      end

      context 'when observability_group_o11y_setting is not persisted' do
        before do
          stub_feature_flags(o11y_settings_access: false)
          stub_member_access_level(group, developer: user)
          allow(group).to receive(:observability_group_o11y_setting).and_return(instance_double(
            Observability::GroupO11ySetting, persisted?: false))
        end

        it 'does not add observability menu items' do
          expected_menu_items = [:setup]

          expect(observability_menu.renderable_items.map(&:item_id)).to match_array(expected_menu_items)
        end
      end
    end

    context 'when o11y_settings_access feature flag is enabled' do
      before do
        stub_feature_flags(observability_sass_features: false, o11y_settings_access: user)
      end

      it 'adds the o11y settings menu item' do
        expected_menu_items = [:o11y_settings, :setup]

        expect(observability_menu.renderable_items.map(&:item_id)).to match_array(expected_menu_items)
      end
    end

    context 'when both feature flags are enabled' do
      before do
        stub_feature_flags(observability_sass_features: group, o11y_settings_access: user)
        allow(group).to receive(:observability_group_o11y_setting).and_return(instance_double(
          Observability::GroupO11ySetting, persisted?: true))
      end

      it 'adds all menu items including o11y settings' do
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
          :settings,
          :o11y_settings,
          :setup
        ]

        expect(observability_menu.renderable_items.map(&:item_id)).to match_array(expected_menu_items)
      end
    end

    context 'when both feature flags are disabled' do
      before do
        stub_feature_flags(observability_sass_features: false, o11y_settings_access: false)
      end

      it 'returns false and does not add any menu items' do
        expect(observability_menu.configure_menu_items).to be false
        expect(observability_menu.renderable_items).to be_empty
      end
    end
  end

  describe 'user login status' do
    let(:group) { build_stubbed(:group, :private) }

    context 'when user is logged in' do
      let(:user) { build_stubbed(:user) }
      let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }

      subject(:observability_menu) { described_class.new(context) }

      before do
        stub_feature_flags(observability_sass_features: group, o11y_settings_access: user)
        allow(group).to receive(:observability_group_o11y_setting).and_return(instance_double(
          Observability::GroupO11ySetting, persisted?: true))
      end

      it 'returns menu items when logged in and features enabled' do
        expect(observability_menu.configure_menu_items).to be true
        expect(observability_menu.renderable_items).not_to be_empty
      end
    end

    context 'when user is not logged in' do
      let(:user) { nil }
      let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }

      subject(:observability_menu) { described_class.new(context) }

      before do
        stub_feature_flags(observability_sass_features: group, o11y_settings_access: false)
        allow(group).to receive(:observability_group_o11y_setting).and_return(instance_double(
          Observability::GroupO11ySetting, persisted?: true))
      end

      it 'returns false and does not add any menu items when not logged in' do
        expect(observability_menu.configure_menu_items).to be false
        expect(observability_menu.renderable_items).to be_empty
      end
    end
  end

  describe '#title, #sprite_icon, #link' do
    before do
      stub_feature_flags(observability_sass_features: group, o11y_settings_access: false)
      stub_member_access_level(group, developer: user)
      allow(group).to receive(:observability_group_o11y_setting).and_return(instance_double(
        Observability::GroupO11ySetting, persisted?: true))
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
    before do
      stub_feature_flags(observability_sass_features: group, o11y_settings_access: false)
      stub_member_access_level(group, developer: user)
      allow(group).to receive(:observability_group_o11y_setting).and_return(instance_double(
        Observability::GroupO11ySetting, persisted?: true))
      observability_menu.configure_menu_items
    end

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
      stub_feature_flags(observability_sass_features: group, o11y_settings_access: false)
      stub_member_access_level(group, developer: user)
      allow(group).to receive(:observability_group_o11y_setting).and_return(instance_double(
        Observability::GroupO11ySetting, persisted?: true))
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
      expect(menu_items.find { |i| i.item_id == :settings }.link).to include('settings')
    end
  end

  describe '#o11y_settings_menu_item' do
    context 'when o11y_settings_access feature flag is enabled' do
      before do
        stub_feature_flags(observability_sass_features: false, o11y_settings_access: user)
        observability_menu.configure_menu_items
      end

      it 'has the right link for o11y settings menu item' do
        menu_items = observability_menu.renderable_items
        o11y_settings_item = menu_items.find { |i| i.item_id == :o11y_settings }

        expect(o11y_settings_item).not_to be_nil
        expect(o11y_settings_item.link).to include('o11y_service_settings')
      end
    end
  end
end
