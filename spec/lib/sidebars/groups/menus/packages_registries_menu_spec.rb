# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::PackagesRegistriesMenu, feature_category: :navigation do
  let_it_be(:owner) { create(:user) }
  let_it_be_with_reload(:group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let_it_be(:harbor_integration) { create(:harbor_integration, group: group, project: nil) }

  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  let(:menu) { described_class.new(context) }

  it_behaves_like 'not serializable as super_sidebar_menu_args'

  describe '#render?' do
    context 'when menu has menu items to show' do
      it 'returns true' do
        expect(menu.render?).to eq true
      end
    end

    context 'when menu does not have any menu item to show' do
      it 'returns false' do
        stub_feature_flags(harbor_registry_integration: false)
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
    let(:harbor_registry_integration) { true }

    before do
      stub_container_registry_config(enabled: registry_enabled)
      stub_config(packages: { enabled: packages_enabled })
      stub_config(dependency_proxy: { enabled: true })
      stub_feature_flags(harbor_registry_integration: harbor_registry_integration)
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

        it 'menu link points to Harbor Registry page' do
          expect(subject).to eq find_menu(menu, :harbor_registry).link
        end

        context 'when Harbor Registry is not visible' do
          let(:harbor_registry_integration) { false }

          it 'menu link points to Dependency Proxy page' do
            expect(subject).to eq find_menu(menu, :dependency_proxy).link
          end
        end
      end
    end
  end

  describe 'Menu items' do
    subject { find_menu(menu, item_id) }

    shared_examples 'the menu entry is available' do
      it 'the menu item is added to list of menu items' do
        is_expected.not_to be_nil
      end
    end

    shared_examples 'the menu entry is not available' do
      it 'the menu item is not added to list of menu items' do
        is_expected.to be_nil
      end
    end

    describe 'Packages Registry' do
      let(:item_id) { :packages_registry }

      context 'when user can read packages' do
        before do
          stub_config(packages: { enabled: packages_enabled })
        end

        context 'when config package setting is disabled' do
          let(:packages_enabled) { false }

          it_behaves_like 'the menu entry is not available'
        end

        context 'when config package setting is enabled' do
          let(:packages_enabled) { true }

          it_behaves_like 'the menu entry is available'
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

          it_behaves_like 'the menu entry is not available'
        end

        context 'when config registry setting is enabled' do
          let(:container_enabled) { true }

          it_behaves_like 'the menu entry is available'

          context 'when user cannot read container images' do
            let(:user) { nil }

            it_behaves_like 'the menu entry is not available'
          end
        end
      end
    end

    describe 'Dependency Proxy' do
      let(:item_id) { :dependency_proxy }

      before do
        stub_config(dependency_proxy: { enabled: dependency_enabled })
      end

      context 'when user can read dependency proxy' do
        context 'when config dependency_proxy is enabled' do
          let(:dependency_enabled) { true }

          it_behaves_like 'the menu entry is available'

          context 'when the group settings exist' do
            let_it_be(:dependency_proxy_group_setting) { create(:dependency_proxy_group_setting, group: group) }

            it_behaves_like 'the menu entry is available'

            context 'when the proxy is disabled at the group level' do
              before do
                dependency_proxy_group_setting.enabled = false
                dependency_proxy_group_setting.save!
              end

              it_behaves_like 'the menu entry is not available'
            end
          end
        end

        context 'when config dependency_proxy is not enabled' do
          let(:dependency_enabled) { false }

          it_behaves_like 'the menu entry is not available'
        end
      end

      context 'when user cannot read dependency proxy' do
        let(:user) { nil }
        let(:dependency_enabled) { true }

        it_behaves_like 'the menu entry is not available'
      end
    end

    describe 'Harbor Registry' do
      let(:item_id) { :harbor_registry }

      before do
        stub_feature_flags(harbor_registry_integration: harbor_registry_enabled)
      end

      context 'when config harbor registry setting is disabled' do
        let(:harbor_registry_enabled) { false }

        it_behaves_like 'the menu entry is not available'
      end

      context 'when config harbor registry setting is enabled' do
        let(:harbor_registry_enabled) { true }

        it_behaves_like 'the menu entry is available'
      end

      context 'when config harbor registry setting is not activated' do
        before do
          harbor_integration.update!(active: false)
        end

        let(:harbor_registry_enabled) { true }

        it_behaves_like 'the menu entry is not available'
      end
    end
  end

  private

  def find_menu(menu, item)
    menu.renderable_items.find { |i| i.item_id == item }
  end
end
