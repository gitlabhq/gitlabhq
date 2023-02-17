# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::ObservabilityMenu do
  let_it_be(:owner) { create(:user) }
  let_it_be(:root_group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:group) { root_group }
  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  let(:menu) { described_class.new(context) }

  describe '#render?' do
    before do
      allow(menu).to receive(:can?).and_call_original
    end

    context 'when observability#explore is allowed' do
      before do
        allow(Gitlab::Observability).to receive(:allowed_for_action?).with(user, group, :explore).and_return(true)
      end

      it 'returns true' do
        expect(menu.render?).to eq true
        expect(Gitlab::Observability).to have_received(:allowed_for_action?).with(user, group, :explore)
      end
    end

    context 'when observability#explore is not allowed' do
      before do
        allow(Gitlab::Observability).to receive(:allowed_for_action?).with(user, group, :explore).and_return(false)
      end

      it 'returns false' do
        expect(menu.render?).to eq false
        expect(Gitlab::Observability).to have_received(:allowed_for_action?).with(user, group, :explore)
      end
    end
  end

  describe "Menu items" do
    before do
      allow(Gitlab::Observability).to receive(:allowed_for_action?).and_return(false)
    end

    subject { find_menu(menu, item_id) }

    shared_examples 'observability menu entry' do
      context 'when action is allowed' do
        before do
          allow(Gitlab::Observability).to receive(:allowed_for_action?).with(user, group, item_id).and_return(true)
        end

        it 'the menu item is added to list of menu items' do
          is_expected.not_to be_nil
        end
      end

      context 'when action is not allowed' do
        before do
          allow(Gitlab::Observability).to receive(:allowed_for_action?).with(user, group, item_id).and_return(false)
        end

        it 'the menu item is added to list of menu items' do
          is_expected.to be_nil
        end
      end
    end

    describe 'Explore' do
      it_behaves_like 'observability menu entry' do
        let(:item_id) { :explore }
      end
    end

    describe 'Datasources' do
      it_behaves_like 'observability menu entry' do
        let(:item_id) { :datasources }
      end
    end
  end

  private

  def find_menu(menu, item)
    menu.renderable_items.find { |i| i.item_id == item }
  end
end
