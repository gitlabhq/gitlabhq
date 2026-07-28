# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::ObserveMenu, feature_category: :observability do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:group) { build_stubbed(:group) }
  let_it_be(:project) { build_stubbed(:project, group: group) }
  let(:context) do
    Sidebars::Projects::Context.new(current_user: user, container: project, show_cluster_hint: true)
  end

  subject(:observe_menu) { described_class.new(context) }

  shared_context 'with observability enabled and setting persisted' do
    before do
      stub_feature_flags(observability_sass_features: project.group)
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
        .with(user, :read_observability_portal, project.group)
        .and_return(true)
      allow(Observability::GroupO11ySetting).to receive(:observability_setting_for)
        .with(project)
        .and_return(instance_double(Observability::GroupO11ySetting, persisted?: true))
      observe_menu.configure_menu_items
    end
  end

  describe '#configure_menu_items' do
    context 'when observability is fully enabled' do
      before do
        stub_feature_flags(observability_sass_features: project.group)
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
          .with(user, :read_observability_portal, project.group)
          .and_return(true)
      end

      context 'when observability setting is persisted' do
        before do
          allow(Observability::GroupO11ySetting).to receive(:observability_setting_for)
            .with(project)
            .and_return(instance_double(Observability::GroupO11ySetting, persisted?: true))
        end

        it 'adds all observability menu items plus setup' do
          expected_items = [
            :logs_explorer, :traces_explorer, :metrics_explorer,
            :infrastructure_monitoring, :services, :observability_dashboard,
            :observability_alerts, :exceptions, :service_map,
            :messaging_queues, :api_monitoring, :notification_channels,
            :api_keys, :setup
          ]

          expect(observe_menu.renderable_items.map(&:item_id)).to eq(expected_items)
        end
      end

      context 'when observability setting is not persisted' do
        before do
          allow(Observability::GroupO11ySetting).to receive(:observability_setting_for)
            .with(project)
            .and_return(nil)
        end

        it 'adds only the setup menu item' do
          expect(observe_menu.renderable_items.map(&:item_id)).to eq([:setup])
        end
      end
    end

    shared_examples 'returns false for configure_menu_items' do
      it 'returns false' do
        expect(observe_menu.configure_menu_items).to be false
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(observability_sass_features: false)
      end

      it_behaves_like 'returns false for configure_menu_items'
    end

    context 'when user does not have permission' do
      before do
        stub_feature_flags(observability_sass_features: project.group)
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
          .with(user, :read_observability_portal, project.group)
          .and_return(false)
      end

      it_behaves_like 'returns false for configure_menu_items'
    end

    context 'when user is not logged in' do
      let(:user) { nil }

      it_behaves_like 'returns false for configure_menu_items'
    end

    context 'when project does not belong to a group' do
      let_it_be(:project) { build_stubbed(:project) }

      before do
        stub_feature_flags(observability_saas_features_user_namespace: project.root_namespace)
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
          .with(user, :read_observability_portal, project)
          .and_return(true)
      end

      it 'renders the menu' do
        expect(observe_menu.configure_menu_items).to be true
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(observability_saas_features_user_namespace: false)
        end

        it_behaves_like 'returns false for configure_menu_items'
      end

      context 'when user does not have permission' do
        before do
          allow(Ability).to receive(:allowed?)
            .with(user, :read_observability_portal, project)
            .and_return(false)
        end

        it_behaves_like 'returns false for configure_menu_items'
      end
    end
  end

  describe 'menu metadata' do
    it 'has the correct title, icon, active routes, and container options', :aggregate_failures do
      expect(observe_menu.title).to eq 'Observe'
      expect(observe_menu.sprite_icon).to eq 'eye'
      expect(observe_menu.active_routes).to eq({ controller: 'projects/observability' })
      expect(observe_menu.extra_container_html_options).to eq({ class: 'shortcuts-observability' })
    end
  end

  describe '#link' do
    include_context 'with observability enabled and setting persisted'

    it 'returns the logs explorer link' do
      expect(observe_menu.link).to eq(observe_menu.send(:logs_explorer_menu_item).link)
    end

    context 'when logs_explorer_menu_item does not render' do
      before do
        allow(observe_menu).to receive(:logs_explorer_menu_item)
          .and_return(instance_double(::Sidebars::MenuItem, render?: false))
      end

      it 'returns nil' do
        expect(observe_menu.link).to be_nil
      end
    end
  end

  describe '#serialize_as_menu_item_args' do
    it 'returns nil' do
      expect(observe_menu.serialize_as_menu_item_args).to be_nil
    end
  end

  describe 'menu items' do
    include_context 'with observability enabled and setting persisted'

    using RSpec::Parameterized::TableSyntax

    where(:item_id, :expected_link_fragment, :has_js_nav_class) do
      :logs_explorer             | 'logs/logs-explorer'              | true
      :traces_explorer           | 'traces-explorer'                 | true
      :metrics_explorer          | 'metrics-explorer/summary'        | true
      :infrastructure_monitoring | 'infrastructure-monitoring/hosts' | true
      :services                  | 'services'                        | true
      :observability_dashboard   | 'dashboard'                       | true
      :observability_alerts      | 'alerts'                          | true
      :exceptions                | 'exceptions'                      | true
      :service_map               | 'service-map'                     | true
      :messaging_queues          | 'messaging-queues'                | true
      :api_monitoring            | 'api-monitoring/explorer'         | true
      :notification_channels     | 'settings/channels'               | true
      :api_keys                  | 'api-keys'                        | true
      :setup                     | 'setup'                           | false
    end

    with_them do
      it 'has the correct link and js-observability-nav class', :aggregate_failures do
        item = observe_menu.renderable_items.find { |i| i.item_id == item_id }

        expect(item.link).to include(expected_link_fragment)

        if has_js_nav_class
          expect(item.container_html_options[:class]).to include('js-observability-nav')
        else
          expect(item.container_html_options[:class]).not_to include('js-observability-nav')
        end
      end
    end
  end
end
