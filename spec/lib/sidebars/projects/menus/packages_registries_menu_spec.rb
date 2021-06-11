# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::PackagesRegistriesMenu do
  let_it_be(:project) { create(:project) }

  let(:user) { project.owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  subject { described_class.new(context) }

  describe '#render?' do
    context 'when menu does not have any menu item to show' do
      it 'returns false' do
        allow(subject).to receive(:has_renderable_items?).and_return(false)

        expect(subject.render?).to eq false
      end
    end

    context 'when menu has menu items to show' do
      it 'returns true' do
        expect(subject.render?).to eq true
      end
    end
  end

  describe '#link' do
    let(:registry_enabled) { true }
    let(:packages_enabled) { true }

    before do
      stub_container_registry_config(enabled: registry_enabled)
      stub_config(packages: { enabled: packages_enabled })
    end

    context 'when Packages Registry is visible' do
      it 'menu link points to Packages Registry page' do
        expect(subject.link).to eq described_class.new(context).renderable_items.find { |i| i.item_id == :packages_registry }.link
      end
    end

    context 'when Packages Registry is not visible' do
      let(:packages_enabled) { false }

      it 'menu link points to Container Registry page' do
        expect(subject.link).to eq described_class.new(context).renderable_items.find { |i| i.item_id == :container_registry }.link
      end

      context 'when Container Registry is not visible' do
        let(:registry_enabled) { false }

        it 'menu link points to Infrastructure Registry page' do
          expect(subject.link).to eq described_class.new(context).renderable_items.find { |i| i.item_id == :infrastructure_registry }.link
        end
      end
    end
  end

  describe 'Menu items' do
    subject { described_class.new(context).renderable_items.find { |i| i.item_id == item_id } }

    describe 'Packages Registry' do
      let(:item_id) { :packages_registry }

      context 'when user can read packages' do
        context 'when config package setting is disabled' do
          it 'the menu item is not added to list of menu items' do
            stub_config(packages: { enabled: false })

            is_expected.to be_nil
          end
        end

        context 'when config package setting is enabled' do
          it 'the menu item is added to list of menu items' do
            stub_config(packages: { enabled: true })

            is_expected.not_to be_nil
          end
        end
      end

      context 'when user cannot read packages' do
        let(:user) { nil }

        it 'the menu item is not added to list of menu items' do
          is_expected.to be_nil
        end
      end
    end

    describe 'Container Registry' do
      let(:item_id) { :container_registry }

      context 'when user can read container images' do
        context 'when config registry setting is disabled' do
          it 'the menu item is not added to list of menu items' do
            stub_container_registry_config(enabled: false)

            is_expected.to be_nil
          end
        end

        context 'when config registry setting is enabled' do
          it 'the menu item is added to list of menu items' do
            stub_container_registry_config(enabled: true)

            is_expected.not_to be_nil
          end
        end
      end

      context 'when user cannot read container images' do
        let(:user) { nil }

        it 'the menu item is not added to list of menu items' do
          is_expected.to be_nil
        end
      end
    end

    describe 'Infrastructure Registry' do
      let(:item_id) { :infrastructure_registry }

      context 'when feature flag :infrastructure_registry_page is enabled' do
        it 'the menu item is added to list of menu items' do
          stub_feature_flags(infrastructure_registry_page: true)

          is_expected.not_to be_nil
        end
      end

      context 'when feature flag :infrastructure_registry_page is disabled' do
        it 'the menu item is not added to list of menu items' do
          stub_feature_flags(infrastructure_registry_page: false)

          is_expected.to be_nil
        end
      end
    end
  end
end
