# frozen_string_literal: true

# require 'fast_spec_helper' -- this no longer runs under fast_spec_helper
require 'spec_helper'

RSpec.describe Sidebars::Concerns::SuperSidebarPanel, feature_category: :navigation do
  let(:menu_class_foo) { Class.new(Sidebars::Menu) }
  let(:menu_foo) { menu_class_foo.new({}) }

  let(:menu_class_bar) do
    Class.new(Sidebars::Menu) do
      def title
        "Bar"
      end

      def pick_into_super_sidebar?
        true
      end
    end
  end

  let(:menu_bar) { menu_class_bar.new({}) }

  subject do
    Class.new(Sidebars::Panel) do
      include Sidebars::Concerns::SuperSidebarPanel
    end.new({})
  end

  before do
    allow(menu_foo).to receive(:render?).and_return(true)
    allow(menu_bar).to receive(:render?).and_return(true)
  end

  describe '#pick_from_old_menus' do
    it 'removes items with #pick_into_super_sidebar? from a list and adds them to the panel menus' do
      old_menus = [menu_foo, menu_bar]

      subject.pick_from_old_menus(old_menus)

      expect(old_menus).to include(menu_foo)
      expect(subject.renderable_menus).not_to include(menu_foo)

      expect(old_menus).not_to include(menu_bar)
      expect(subject.renderable_menus).to include(menu_bar)
    end
  end

  describe '#transform_old_menus' do
    let(:uncategorized_menu) { ::Sidebars::UncategorizedMenu.new({}) }

    let(:menu_item) do
      Sidebars::MenuItem.new(title: 'foo3', link: 'foo3', active_routes: { controller: 'barc' },
        super_sidebar_parent: menu_class_foo)
    end

    let(:nil_menu_item) { Sidebars::NilMenuItem.new(item_id: :nil_item) }
    let(:existing_item) do
      Sidebars::MenuItem.new(
        item_id: :exists,
        title: 'Existing item',
        link: 'foo2',
        active_routes: { controller: 'foo2' }
      )
    end

    let(:current_menus) { [menu_foo, uncategorized_menu] }

    before do
      allow(menu_bar).to receive(:serialize_as_menu_item_args).and_return(nil)
      menu_foo.add_item(existing_item)
    end

    context 'for Menus with Menu Items' do
      before do
        menu_bar.add_item(menu_item)
        menu_bar.add_item(nil_menu_item)
      end

      it 'adds Menu Items to defined super_sidebar_parent' do
        subject.transform_old_menus(current_menus, menu_bar)

        expect(menu_foo.renderable_items).to eq([existing_item, menu_item])
        expect(uncategorized_menu.renderable_items).to eq([])
      end

      it 'replaces placeholder Menu Items in the defined super_sidebar_parent' do
        menu_foo.insert_item_before(:exists, nil_menu_item)
        allow(menu_item).to receive(:item_id).and_return(:nil_item)

        subject.transform_old_menus(current_menus, menu_bar)

        expect(menu_foo.renderable_items).to eq([menu_item, existing_item])
        expect(uncategorized_menu.renderable_items).to eq([])
      end

      it 'considers Menu Items uncategorized if super_sidebar_parent is nil' do
        allow(menu_item).to receive(:super_sidebar_parent).and_return(nil)
        subject.transform_old_menus(current_menus, menu_bar)

        expect(menu_foo.renderable_items).to eq([existing_item])
        expect(uncategorized_menu.renderable_items).to eq([menu_item])
      end

      it 'considers Menu Items uncategorized if super_sidebar_parent cannot be found' do
        allow(menu_item).to receive(:super_sidebar_parent).and_return(menu_class_bar)
        subject.transform_old_menus(current_menus, menu_bar)

        expect(menu_foo.renderable_items).to eq([existing_item])
        expect(uncategorized_menu.renderable_items).to eq([menu_item])
      end

      it 'considers Menu Items deleted if super_sidebar_parent is Sidebars::NilMenuItem' do
        allow(menu_item).to receive(:super_sidebar_parent).and_return(::Sidebars::NilMenuItem)
        subject.transform_old_menus(current_menus, menu_bar)

        expect(menu_foo.renderable_items).to eq([existing_item])
        expect(uncategorized_menu.renderable_items).to eq([])
      end
    end

    it 'converts "solo" top-level Menu entry to Menu Item' do
      allow(Sidebars::MenuItem).to receive(:new).and_return(menu_item)
      allow(menu_bar).to receive(:serialize_as_menu_item_args).and_return({})

      subject.transform_old_menus(current_menus, menu_bar)

      expect(menu_foo.renderable_items).to eq([existing_item, menu_item])
      expect(uncategorized_menu.renderable_items).to eq([])
    end

    it 'drops "solo" top-level Menu entries, if they serialize to nil' do
      allow(Sidebars::MenuItem).to receive(:new).and_return(menu_item)
      allow(menu_bar).to receive(:serialize_as_menu_item_args).and_return(nil)

      subject.transform_old_menus(current_menus, menu_bar)

      expect(menu_foo.renderable_items).to eq([existing_item])
      expect(uncategorized_menu.renderable_items).to eq([])
    end
  end
end
