# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::MonitoringMenu, feature_category: :navigation do
  let(:user) { build_stubbed(:user, :admin) }
  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }
  let(:menu) { described_class.new(context) }

  it_behaves_like 'Admin menu',
    link: '/admin/system_info',
    title: s_('Admin|Monitoring'),
    icon: 'monitor'

  it_behaves_like 'Admin menu with sub menus'

  describe 'Menu items', :enable_admin_mode do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    describe 'Metrics Dashboard' do
      let(:item_id) { :metrics_dashboard }

      before do
        stub_application_setting(grafana_enabled: grafana_enabled)
      end

      context 'when grafana is enabled' do
        let(:grafana_enabled) { true }

        it { is_expected.not_to be_nil }
      end

      context 'when grafana is disabled' do
        let(:grafana_enabled) { false }

        it { is_expected.to be_nil }
      end
    end
  end
end
