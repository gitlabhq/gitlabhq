# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::CiCdMenu do
  let_it_be(:owner) { create(:user) }
  let_it_be(:root_group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:group) { root_group }
  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }

  describe 'Menu Items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    describe 'Runners' do
      let(:item_id) { :runners }

      specify { is_expected.not_to be_nil }

      describe 'when feature flag :runner_list_group_view_vue_ui is disabled' do
        before do
          stub_feature_flags(runner_list_group_view_vue_ui: false)
        end

        specify { is_expected.to be_nil }
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end
  end
end
