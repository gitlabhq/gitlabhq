# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::SuperSidebarPanel, feature_category: :navigation do
  let(:project) { build_stubbed(:project, :repository) }

  let(:user) { project.first_owner }
  let(:context) do
    Sidebars::Projects::Context.new(
      current_user: user,
      container: project,
      current_ref: project.repository.root_ref,
      is_super_sidebar: true,
      # Turn features on that impact the list of items rendered
      can_view_pipeline_editor: true,
      learn_gitlab_enabled: true,
      show_get_started_menu: false,
      show_discover_project_security: true,
      # Turn features off that do not add/remove items
      show_cluster_hint: false,
      show_promotions: false
    )
  end

  subject { described_class.new(context) }

  before do
    # Enable integrations with menu items
    allow(project).to receive(:external_wiki).and_return(build(:external_wiki_integration, project: project))
    allow(project).to receive(:external_issue_tracker).and_return(build(:bugzilla_integration, project: project))
  end

  it 'implements #super_sidebar_context_header' do
    expect(subject.super_sidebar_context_header).to eq(_('Project'))
  end

  describe '#renderable_menus' do
    let(:category_menu) do
      [
        Sidebars::StaticMenu,
        Sidebars::Projects::SuperSidebarMenus::ManageMenu,
        Sidebars::Projects::SuperSidebarMenus::PlanMenu,
        Sidebars::Projects::SuperSidebarMenus::CodeMenu,
        Sidebars::Projects::SuperSidebarMenus::BuildMenu,
        Sidebars::Projects::SuperSidebarMenus::SecureMenu,
        Sidebars::Projects::SuperSidebarMenus::DeployMenu,
        Sidebars::Projects::SuperSidebarMenus::OperationsMenu,
        Sidebars::Projects::SuperSidebarMenus::MonitorMenu,
        Sidebars::Projects::SuperSidebarMenus::AnalyzeMenu,
        Sidebars::UncategorizedMenu,
        Sidebars::Projects::Menus::SettingsMenu
      ]
    end

    it "is exposed as a renderable menu" do
      expect(subject.instance_variable_get(:@menus).map(&:class)).to include(*category_menu)
    end

    context 'when the project belongs to a group' do
      let(:group) { build_stubbed(:group, namespace_settings: build_stubbed(:namespace_settings)) }
      let(:project) { build_stubbed(:project, :repository, group: group) }
      let(:user) { build_stubbed(:user) }

      context 'when observability_sass_features is enabled' do
        before do
          stub_feature_flags(observability_sass_features: project.group)
        end

        it 'includes ObserveMenu' do
          expect(subject.instance_variable_get(:@menus).map(&:class))
            .to include(Sidebars::Projects::SuperSidebarMenus::ObserveMenu)
        end
      end

      context 'when observability_sass_features is disabled' do
        before do
          stub_feature_flags(observability_sass_features: false)
        end

        it 'does not include ObserveMenu' do
          expect(subject.instance_variable_get(:@menus).map(&:class))
            .not_to include(Sidebars::Projects::SuperSidebarMenus::ObserveMenu)
        end
      end
    end

    context 'when the project belongs to a personal namespace' do
      context 'when observability_saas_features_user_namespace is enabled' do
        before do
          stub_feature_flags(observability_saas_features_user_namespace: project.root_namespace)
        end

        it 'includes ObserveMenu' do
          expect(subject.instance_variable_get(:@menus).map(&:class))
            .to include(Sidebars::Projects::SuperSidebarMenus::ObserveMenu)
        end
      end

      context 'when observability_saas_features_user_namespace is disabled' do
        before do
          stub_feature_flags(observability_saas_features_user_namespace: false)
        end

        it 'does not include ObserveMenu' do
          expect(subject.instance_variable_get(:@menus).map(&:class))
            .not_to include(Sidebars::Projects::SuperSidebarMenus::ObserveMenu)
        end
      end
    end
  end

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel with all menu_items categorized'
  it_behaves_like 'a panel instantiable by the anonymous user'
end
