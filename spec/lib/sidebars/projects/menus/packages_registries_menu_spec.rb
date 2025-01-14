# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::PackagesRegistriesMenu, feature_category: :navigation do
  let_it_be(:project) { create(:project) }

  let_it_be(:harbor_integration) { create(:harbor_integration, project: project) }

  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  subject { described_class.new(context) }

  it_behaves_like 'not serializable as super_sidebar_menu_args' do
    let(:menu) { subject }
  end

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
      stub_feature_flags(agent_registry: false)
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

        it 'displays menu link' do
          expect(subject.render?).to eq true
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

      it 'the menu item is added to list of menu items' do
        is_expected.not_to be_nil
      end

      context 'when config package setting is disabled' do
        it 'does not add the menu item to the list' do
          stub_config(packages: { enabled: false })

          is_expected.to be_nil
        end
      end

      context 'when user cannot read packages' do
        let(:user) { nil }

        it 'does not add the menu item to the list' do
          is_expected.to be_nil
        end
      end
    end

    describe 'Harbor Registry' do
      let(:item_id) { :harbor_registry }

      it 'the menu item is added to list of menu items' do
        is_expected.not_to be_nil
        expect(subject.active_routes[:controller]).to eq('projects/harbor/repositories')
      end

      context 'when config harbor registry setting is not activated' do
        it 'does not add the menu item to the list' do
          project.harbor_integration.update!(active: false)

          is_expected.to be_nil
        end
      end
    end

    describe 'Model experiments' do
      let(:item_id) { :model_experiments }

      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                             .with(user, :read_model_experiments, project)
                             .and_return(model_experiments_enabled)
      end

      context 'when user can access model experiments' do
        let(:model_experiments_enabled) { true }

        it 'shows the menu item' do
          is_expected.not_to be_nil
        end
      end

      context 'when user does not have access model experiments' do
        let(:model_experiments_enabled) { false }

        it 'does not show the menu item' do
          is_expected.to be_nil
        end
      end
    end

    describe 'Model registry' do
      let(:item_id) { :model_registry }

      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                            .with(user, :read_model_registry, project)
                            .and_return(model_registry_enabled)
      end

      context 'when user can read model registry' do
        let(:model_registry_enabled) { true }

        it 'shows the menu item' do
          is_expected.not_to be_nil
        end
      end

      context 'when user can not read model registry' do
        let(:model_registry_enabled) { false }

        it 'does not show the menu item' do
          is_expected.to be_nil
        end
      end
    end
  end
end
