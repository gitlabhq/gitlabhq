# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::KubernetesMenu, :request_store, feature_category: :navigation do
  let_it_be(:owner) { create(:user) }
  let_it_be(:group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  let(:menu) { described_class.new(context) }

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:extra_attrs) do
      {
        super_sidebar_parent: Sidebars::Groups::SuperSidebarMenus::OperationsMenu,
        item_id: :group_kubernetes_clusters
      }
    end
  end

  describe '#render?' do
    context 'when user can read clusters' do
      it 'returns true' do
        expect(menu.render?).to eq true
      end
    end

    context 'when user cannot read clusters rules' do
      let(:user) { nil }

      it 'returns false' do
        expect(menu.render?).to eq false
      end
    end

    context ':certificate_based_clusters feature flag is disabled' do
      before do
        stub_feature_flags(certificate_based_clusters: false)
      end

      it 'returns false' do
        expect(menu.render?).to eq false
      end
    end
  end
end
