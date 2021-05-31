# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Menu do
  let(:menu) { described_class.new(context) }
  let(:context) { Sidebars::Context.new(current_user: nil, container: nil) }
  let(:nil_menu_item) { Sidebars::NilMenuItem.new(item_id: :foo) }

  describe '#all_active_routes' do
    it 'gathers all active routes of items and the current menu' do
      menu.add_item(Sidebars::MenuItem.new(title: 'foo1', link: 'foo1', active_routes: { path: %w(bar test) }))
      menu.add_item(Sidebars::MenuItem.new(title: 'foo2', link: 'foo2', active_routes: { controller: 'fooc' }))
      menu.add_item(Sidebars::MenuItem.new(title: 'foo3', link: 'foo3', active_routes: { controller: 'barc' }))
      menu.add_item(nil_menu_item)

      allow(menu).to receive(:active_routes).and_return({ path: 'foo' })

      expect(menu).to receive(:renderable_items).and_call_original
      expect(menu.all_active_routes).to eq({ path: %w(foo bar test), controller: %w(fooc barc) })
    end
  end

  describe '#render?' do
    context 'when the menus has no items' do
      it 'returns false' do
        expect(menu.render?).to be false
      end
    end

    context 'when the menu has items' do
      it 'returns true' do
        menu.add_item(Sidebars::MenuItem.new(title: 'foo1', link: 'foo1', active_routes: {}))

        expect(menu.render?).to be true
      end

      context 'when menu items are NilMenuItem' do
        it 'returns false' do
          menu.add_item(nil_menu_item)

          expect(menu.render?).to be false
        end
      end
    end
  end

  describe '#has_items?' do
    it 'returns true when there are regular menu items' do
      menu.add_item(Sidebars::MenuItem.new(title: 'foo1', link: 'foo1', active_routes: {}))

      expect(menu.has_items?).to be true
    end

    it 'returns true when there are nil menu items' do
      menu.add_item(nil_menu_item)

      expect(menu.has_items?).to be true
    end
  end

  describe '#has_renderable_items?' do
    it 'returns true when there are regular menu items' do
      menu.add_item(Sidebars::MenuItem.new(title: 'foo1', link: 'foo1', active_routes: {}))

      expect(menu.has_renderable_items?).to be true
    end

    it 'returns false when there are nil menu items' do
      menu.add_item(nil_menu_item)

      expect(menu.has_renderable_items?).to be false
    end

    it 'returns true when there are both regular and nil menu items' do
      menu.add_item(Sidebars::MenuItem.new(title: 'foo1', link: 'foo1', active_routes: {}))
      menu.add_item(nil_menu_item)

      expect(menu.has_renderable_items?).to be true
    end
  end

  describe '#renderable_items' do
    it 'returns only regular menu items' do
      item = Sidebars::MenuItem.new(title: 'foo1', link: 'foo1', active_routes: {})
      menu.add_item(item)
      menu.add_item(nil_menu_item)

      expect(menu.renderable_items.size).to eq 1
      expect(menu.renderable_items.first).to eq item
    end
  end

  describe '#insert_element_before' do
    let(:item1) { Sidebars::MenuItem.new(title: 'foo1', link: 'foo1', active_routes: {}, item_id: :foo1) }
    let(:item2) { Sidebars::MenuItem.new(title: 'foo2', link: 'foo2', active_routes: {}, item_id: :foo2) }
    let(:item3) { Sidebars::MenuItem.new(title: 'foo3', link: 'foo3', active_routes: {}, item_id: :foo3) }
    let(:list) { [item1, item2] }

    it 'adds element before the specific element class' do
      menu.insert_element_before(list, :foo2, item3)

      expect(list).to eq [item1, item3, item2]
    end

    it 'does not add nil elements' do
      menu.insert_element_before(list, :foo2, nil)

      expect(list).to eq [item1, item2]
    end

    context 'when reference element does not exist' do
      it 'adds the element to the top of the list' do
        menu.insert_element_before(list, :non_existent, item3)

        expect(list).to eq [item3, item1, item2]
      end
    end
  end

  describe '#insert_element_after' do
    let(:item1) { Sidebars::MenuItem.new(title: 'foo1', link: 'foo1', active_routes: {}, item_id: :foo1) }
    let(:item2) { Sidebars::MenuItem.new(title: 'foo2', link: 'foo2', active_routes: {}, item_id: :foo2) }
    let(:item3) { Sidebars::MenuItem.new(title: 'foo3', link: 'foo3', active_routes: {}, item_id: :foo3) }
    let(:list) { [item1, item2] }

    it 'adds element after the specific element class' do
      menu.insert_element_after(list, :foo1, item3)

      expect(list).to eq [item1, item3, item2]
    end

    it 'does not add nil elements' do
      menu.insert_element_after(list, :foo1, nil)

      expect(list).to eq [item1, item2]
    end

    context 'when reference element does not exist' do
      it 'adds the element to the end of the list' do
        menu.insert_element_after(list, :non_existent, item3)

        expect(list).to eq [item1, item2, item3]
      end
    end
  end

  describe '#container_html_options' do
    before do
      allow(menu).to receive(:title).and_return('Foo Menu')
    end

    context 'when menu can be rendered' do
      before do
        allow(menu).to receive(:render?).and_return(true)
      end

      context 'when menu has renderable items' do
        before do
          menu.add_item(Sidebars::MenuItem.new(title: 'foo1', link: 'foo1', active_routes: { path: 'bar' }))
        end

        it 'contains the special class' do
          expect(menu.container_html_options[:class]).to eq 'has-sub-items'
        end

        context 'when menu already has other classes' do
          it 'appends special class' do
            allow(menu).to receive(:extra_container_html_options).and_return(class: 'foo')

            expect(menu.container_html_options[:class]).to eq 'foo has-sub-items'
          end
        end
      end

      context 'when menu does not have renderable items' do
        it 'does not contain the special class' do
          expect(menu.container_html_options[:class]).to be_nil
        end
      end
    end

    context 'when menu cannot be rendered' do
      before do
        allow(menu).to receive(:render?).and_return(false)
      end

      it 'does not contain special class' do
        expect(menu.container_html_options[:class]).to be_nil
      end
    end
  end
end
