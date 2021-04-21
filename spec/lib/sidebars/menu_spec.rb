# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Menu do
  let(:menu) { described_class.new(context) }
  let(:context) { Sidebars::Context.new(current_user: nil, container: nil) }

  describe '#all_active_routes' do
    it 'gathers all active routes of items and the current menu' do
      menu_item1 = Sidebars::MenuItem.new(context)
      menu_item2 = Sidebars::MenuItem.new(context)
      menu_item3 = Sidebars::MenuItem.new(context)
      menu.add_item(menu_item1)
      menu.add_item(menu_item2)
      menu.add_item(menu_item3)

      allow(menu).to receive(:active_routes).and_return({ path: 'foo' })
      allow(menu_item1).to receive(:active_routes).and_return({ path: %w(bar test) })
      allow(menu_item2).to receive(:active_routes).and_return({ controller: 'fooc' })
      allow(menu_item3).to receive(:active_routes).and_return({ controller: 'barc' })

      expect(menu.all_active_routes).to eq({ path: %w(foo bar test), controller: %w(fooc barc) })
    end

    it 'does not include routes for non renderable items' do
      menu_item = Sidebars::MenuItem.new(context)
      menu.add_item(menu_item)

      allow(menu).to receive(:active_routes).and_return({ path: 'foo' })
      allow(menu_item).to receive(:render?).and_return(false)
      allow(menu_item).to receive(:active_routes).and_return({ controller: 'bar' })

      expect(menu.all_active_routes).to eq({ path: ['foo'] })
    end
  end

  describe '#render?' do
    context 'when the menus has no items' do
      it 'returns true' do
        expect(menu.render?).to be true
      end
    end

    context 'when the menu has items' do
      let(:menu_item) { Sidebars::MenuItem.new(context) }

      before do
        menu.add_item(menu_item)
      end

      context 'when items are not renderable' do
        it 'returns false' do
          allow(menu_item).to receive(:render?).and_return(false)

          expect(menu.render?).to be false
        end
      end

      context 'when there are renderable items' do
        it 'returns true' do
          expect(menu.render?).to be true
        end
      end
    end
  end
end
