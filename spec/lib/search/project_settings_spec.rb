# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Search results for project settings", :js, feature_category: :global_search, type: :feature do
  it_behaves_like 'all project settings sections exist and have correct anchor links'
end

RSpec.describe Search::ProjectSettings, feature_category: :global_search do
  let_it_be(:project) { create(:project) }

  subject(:project_settings) { described_class.new(project) }

  describe '#general_settings' do
    it 'includes Service Desk when supported' do
      allow(::ServiceDesk).to receive(:supported?).and_return(true)

      settings = project_settings.general_settings

      service_desk_setting = settings.find { |s| s[:text] == _("Service Desk") }
      expect(service_desk_setting).to be_present
      expect(service_desk_setting[:href]).to eq(
        Rails.application.routes.url_helpers.edit_project_path(project, anchor: 'js-service-desk')
      )
    end

    it 'excludes Service Desk when not supported' do
      allow(::ServiceDesk).to receive(:supported?).and_return(false)

      settings = project_settings.general_settings

      service_desk_setting = settings.find { |s| s[:text] == _("Service Desk") }
      expect(service_desk_setting).to be_nil
    end

    it 'returns all general settings when Service Desk is supported' do
      allow(::ServiceDesk).to receive(:supported?).and_return(true)

      settings = project_settings.general_settings

      expect(settings.pluck(:text)).to contain_exactly(
        _("Naming, description, topics"),
        _("Visibility, project features, permissions"),
        _("Badges"),
        _("Service Desk"),
        _("Advanced")
      )
    end

    it 'returns general settings without Service Desk when not supported' do
      allow(::ServiceDesk).to receive(:supported?).and_return(false)

      settings = project_settings.general_settings

      expect(settings.pluck(:text)).to contain_exactly(
        _("Naming, description, topics"),
        _("Visibility, project features, permissions"),
        _("Badges"),
        _("Advanced")
      )
    end
  end
end
