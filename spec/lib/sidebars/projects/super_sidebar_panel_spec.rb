# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::SuperSidebarPanel, feature_category: :navigation do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.first_owner }

  let(:context) do
    double("Stubbed context", current_user: user, container: project, project: project, current_ref: 'master').as_null_object # rubocop:disable RSpec/VerifiedDoubles
  end

  subject { described_class.new(context) }

  it 'implements #super_sidebar_context_header' do
    expect(subject.super_sidebar_context_header).to eq(
      {
        title: project.name,
        avatar: project.avatar_url,
        id: project.id
      })
  end

  describe '#renderable_menus' do
    let(:category_menu) do
      [
        Sidebars::StaticMenu,
        Sidebars::Projects::SuperSidebarMenus::PlanMenu,
        Sidebars::Projects::Menus::RepositoryMenu,
        Sidebars::Projects::Menus::CiCdMenu,
        Sidebars::Projects::Menus::SecurityComplianceMenu,
        Sidebars::Projects::Menus::DeploymentsMenu,
        Sidebars::Projects::Menus::PackagesRegistriesMenu,
        Sidebars::Projects::Menus::InfrastructureMenu,
        Sidebars::Projects::Menus::MonitorMenu,
        Sidebars::Projects::Menus::AnalyticsMenu,
        Sidebars::UncategorizedMenu,
        Sidebars::Projects::Menus::SettingsMenu
      ]
    end

    it "is exposed as a renderable menu" do
      expect(subject.renderable_menus.map(&:class)).to eq(category_menu)
    end
  end
end
