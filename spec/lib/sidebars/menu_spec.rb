# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Menu, feature_category: :navigation do
  let(:menu) { described_class.new(context) }
  let(:context) { Sidebars::Context.new(current_user: nil, container: nil) }

  let(:nil_menu_item) { Sidebars::NilMenuItem.new(item_id: :foo) }

  describe '#all_active_routes' do
    it 'gathers all active routes of items and the current menu' do
      menu.add_item(Sidebars::MenuItem.new(title: 'foo1', link: 'foo1', active_routes: { path: %w[bar test] }))
      menu.add_item(Sidebars::MenuItem.new(title: 'foo2', link: 'foo2', active_routes: { controller: 'fooc' }))
      menu.add_item(Sidebars::MenuItem.new(title: 'foo3', link: 'foo3', active_routes: { controller: 'barc' }))
      menu.add_item(nil_menu_item)

      allow(menu).to receive(:active_routes).and_return({ path: 'foo' })

      expect(menu).to receive(:renderable_items).and_call_original
      expect(menu.all_active_routes).to eq({ path: %w[foo bar test], controller: %w[fooc barc] })
    end
  end

  describe '#serialize_for_super_sidebar' do
    before do
      allow(menu).to receive(:title).and_return('Title')
      allow(menu).to receive(:active_routes).and_return({ path: 'foo' })
    end

    it 'returns a tree-like structure of itself and all menu items' do
      menu.add_item(Sidebars::MenuItem.new(
        item_id: 'id1',
        title: 'Is active',
        link: 'foo2',
        avatar: '/avatar.png',
        entity_id: 123,
        active_routes: { controller: 'fooc' }
      ))
      menu.add_item(Sidebars::MenuItem.new(
        item_id: 'id2',
        title: 'Not active',
        link: 'foo3',
        active_routes: { controller: 'barc' },
        has_pill: true,
        pill_count: 10
      ))
      menu.add_item(nil_menu_item)

      allow(context).to receive(:route_is_active).and_return(->(x) { x[:controller] == 'fooc' })

      expect(menu.serialize_for_super_sidebar).to eq(
        {
          title: "Title",
          id: 'menu',
          avatar_shape: 'rect',
          link: "foo2",
          is_active: true,
          separated: false,
          items: [
            {
              id: 'id1',
              title: "Is active",
              avatar: '/avatar.png',
              entity_id: 123,
              link: "foo2",
              is_active: true
            },
            {
              id: 'id2',
              title: "Not active",
              link: "foo3",
              is_active: false,
              pill_count: 10
            }
          ]
        })
    end

    it 'returns pill data if defined' do
      allow(menu).to receive(:has_pill?).and_return(true)
      allow(menu).to receive(:pill_count).and_return('foo')
      expect(menu.serialize_for_super_sidebar).to eq(
        {
          title: "Title",
          id: 'menu',
          avatar_shape: 'rect',
          is_active: false,
          pill_count: 'foo',
          separated: false,
          items: []
        })
    end

    it 'returns pill_count_field if defined' do
      allow(menu).to receive(:has_pill?).and_return(true)
      allow(menu).to receive(:pill_count_field).and_return('foo')
      expect(menu.serialize_for_super_sidebar).to eq(
        {
          title: "Title",
          id: 'menu',
          avatar_shape: 'rect',
          is_active: false,
          pill_count_field: 'foo',
          separated: false,
          items: []
        })
    end
  end

  describe '#serialize_as_menu_item_args' do
    it 'returns hash of title, link, active_routes, container_html_options' do
      allow(menu).to receive(:title).and_return('Title')
      allow(menu).to receive(:active_routes).and_return({ path: 'foo' })
      allow(menu).to receive(:container_html_options).and_return({ class: 'foo' })
      allow(menu).to receive(:link).and_return('/link')

      expect(menu.serialize_as_menu_item_args).to eq({
        title: 'Title',
        link: '/link',
        active_routes: { path: 'foo' },
        container_html_options: { class: 'foo' }
      })
    end
  end

  describe '#render?' do
    context 'when the menus has no items' do
      it 'returns false' do
        expect(menu.render?).to be false
      end

      context 'when menu has a partial' do
        it 'returns true' do
          allow(menu).to receive(:menu_partial).and_return('foo')

          expect(menu.render?).to be true
        end
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

  describe '#replace_placeholder' do
    let(:item1) { Sidebars::NilMenuItem.new(item_id: :foo1) }
    let(:item2) { Sidebars::MenuItem.new(item_id: :foo2, title: 'foo2', link: 'foo2', active_routes: {}) }
    let(:item3) { Sidebars::NilMenuItem.new(item_id: :foo3) }

    subject { menu.instance_variable_get(:@items) }

    before do
      menu.add_item(item1)
      menu.add_item(item2)
      menu.add_item(item3)
    end

    context 'when a NilMenuItem reference element exists' do
      it 'replaces the reference element with the provided item' do
        item = Sidebars::MenuItem.new(item_id: :foo1, title: 'target', active_routes: {}, link: 'target')
        menu.replace_placeholder(item)

        expect(subject).to eq [item, item2, item3]
      end
    end

    context 'when a MenuItem reference element exists' do
      it 'does not replace the reference element and adds to the end of the list' do
        item = Sidebars::MenuItem.new(item_id: :foo2, title: 'target', active_routes: {}, link: 'target')
        menu.replace_placeholder(item)

        expect(subject).to eq [item1, item2, item3, item]
      end
    end

    context 'when reference element does not exist' do
      it 'adds the element to the end of the list' do
        item = Sidebars::MenuItem.new(item_id: :new_element, title: 'target', active_routes: {}, link: 'target')
        menu.replace_placeholder(item)

        expect(subject).to eq [item1, item2, item3, item]
      end
    end
  end

  describe '#remove_element' do
    let(:item1) { Sidebars::MenuItem.new(title: 'foo1', link: 'foo1', active_routes: {}, item_id: :foo1) }
    let(:item2) { Sidebars::MenuItem.new(title: 'foo2', link: 'foo2', active_routes: {}, item_id: :foo2) }
    let(:item3) { Sidebars::MenuItem.new(title: 'foo3', link: 'foo3', active_routes: {}, item_id: :foo3) }
    let(:list) { [item1, item2, item3] }

    it 'removes specific element' do
      menu.remove_element(list, :foo2)

      expect(list).to eq [item1, item3]
    end

    it 'does not remove nil elements' do
      menu.remove_element(list, nil)

      expect(list).to eq [item1, item2, item3]
    end
  end

  describe "#remove_item" do
    let(:item) { Sidebars::MenuItem.new(title: 'foo1', link: 'foo1', active_routes: {}, item_id: :foo1) }

    before do
      menu.add_item(item)
    end

    it 'removes the item from the menu' do
      menu.remove_item(item)
      expect(menu.has_items?).to be false
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

  describe '#link' do
    let(:foo_path) { '/foo_path' }

    let(:foo_menu) do
      ::Sidebars::MenuItem.new(
        title: 'foo',
        link: foo_path,
        active_routes: {},
        item_id: :foo
      )
    end

    it 'returns first visible menu item link' do
      menu.add_item(foo_menu)

      expect(menu.link).to eq foo_path
    end

    it 'returns nil if there are no visible menu items' do
      expect(menu.link).to be_nil
    end
  end
end
