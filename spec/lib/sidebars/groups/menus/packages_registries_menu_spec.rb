# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::PackagesRegistriesMenu do
  let_it_be(:owner) { create(:user) }
  let_it_be(:group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  let(:menu) { described_class.new(context) }

  describe '#render?' do
    context 'when menu has menu items to show' do
      it 'returns true' do
        expect(menu.render?).to eq true
      end
    end

    context 'when menu does not have any menu item to show' do
      it 'returns false' do
        stub_container_registry_config(enabled: false)
        stub_config(packages: { enabled: false })
        stub_config(dependency_proxy: { enabled: false })

        expect(menu.render?).to eq false
      end
    end
  end

  describe '#link' do
    let(:registry_enabled) { true }
    let(:packages_enabled) { true }

    before do
      stub_container_registry_config(enabled: registry_enabled)
      stub_config(packages: { enabled: packages_enabled })
      stub_config(dependency_proxy: { enabled: true })
    end

    subject { menu.link }

    context 'when Packages Registry is visible' do
      it 'menu link points to Packages Registry page' do
        expect(subject).to eq find_menu(menu, :packages_registry).link
      end
    end

    context 'when Packages Registry is not visible' do
      let(:packages_enabled) { false }

      it 'menu link points to Container Registry page' do
        expect(subject).to eq find_menu(menu, :container_registry).link
      end

      context 'when Container Registry is not visible' do
        let(:registry_enabled) { false }

        it 'menu link points to Dependency Proxy page' do
          expect(subject).to eq find_menu(menu, :dependency_proxy).link
        end
      end
    end
  end

  describe 'Menu items' do
    subject { find_menu(menu, item_id) }

    describe 'Packages Registry' do
      let(:item_id) { :packages_registry }

      context 'when user can read packages' do
        before do
          stub_config(packages: { enabled: packages_enabled })
        end

        context 'when config package setting is disabled' do
          let(:packages_enabled) { false }

          it 'the menu item is not added to list of menu items' do
            is_expected.to be_nil
          end
        end

        context 'when config package setting is enabled' do
          let(:packages_enabled) { true }

          it 'the menu item is added to list of menu items' do
            is_expected.not_to be_nil
          end
        end
      end
    end

    describe 'Container Registry' do
      let(:item_id) { :container_registry }

      context 'when user can read container images' do
        before do
          stub_container_registry_config(enabled: container_enabled)
        end

        context 'when config registry setting is disabled' do
          let(:container_enabled) { false }

          it 'the menu item is not added to list of menu items' do
            is_expected.to be_nil
          end
        end

        context 'when config registry setting is enabled' do
          let(:container_enabled) { true }

          it 'the menu item is added to list of menu items' do
            is_expected.not_to be_nil
          end

          context 'when user cannot read container images' do
            let(:user) { nil }

            it 'the menu item is not added to list of menu items' do
              is_expected.to be_nil
            end
          end
        end
      end
    end

    describe 'Dependency Proxy' do
      let(:item_id) { :dependency_proxy }

      before do
        stub_config(dependency_proxy: { enabled: dependency_enabled })
      end

      context 'when config dependency_proxy is enabled' do
        let(:dependency_enabled) { true }

        it 'the menu item is added to list of menu items' do
          is_expected.not_to be_nil
        end
      end

      context 'when config dependency_proxy is not enabled' do
        let(:dependency_enabled) { false }

        it 'the menu item is not added to list of menu items' do
          is_expected.to be_nil
        end
      end
    end
  end

  private

  def find_menu(menu, item)
    menu.renderable_items.find { |i| i.item_id == item }
  end
end
