# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/labels/_nav', :aggregate_failures, feature_category: :team_planning do
  include LabelsHelper

  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:user) { build_stubbed(:user) }

  before do
    assign(:project, project)
  end

  context 'when archived param is not set' do
    before do
      render 'shared/labels/nav', labels_or_filters: true, can_admin_label: false
    end

    it 'shows Active and Archived tabs' do
      expected_active_href = project_labels_path(project)
      expected_archived_href = project_labels_path(project, archived: 'true')

      expect(rendered).to have_link('Active', href: expected_active_href)
      expect(rendered).to have_link('Archived', href: expected_archived_href)
    end

    it 'marks Active tab as active' do
      expect(rendered).to have_css('.gl-tab-nav-item.active', text: 'Active')
      expect(rendered).not_to have_css('.gl-tab-nav-item.active', text: 'Archived')
    end
  end

  context 'when archived param is true' do
    before do
      controller.params[:archived] = 'true'
      render 'shared/labels/nav', labels_or_filters: true, can_admin_label: false
    end

    it 'marks Archived tab as active' do
      expect(rendered).to have_css('.gl-tab-nav-item.active', text: 'Archived')
      expect(rendered).not_to have_css('.gl-tab-nav-item.active', text: 'Active')
    end
  end

  context 'when archived param is false' do
    before do
      controller.params[:archived] = 'false'
      render 'shared/labels/nav', labels_or_filters: true, can_admin_label: false
    end

    it 'marks Archived tab as active' do
      expect(rendered).not_to have_css('.gl-tab-nav-item.active', text: 'Archived')
      expect(rendered).to have_css('.gl-tab-nav-item.active', text: 'Active')
    end
  end

  context 'when labels_archive feature flag is disabled' do
    before do
      stub_feature_flags(labels_archive: false)
    end

    it 'shows All tab instead of Active/Archived' do
      render 'shared/labels/nav', labels_or_filters: true, can_admin_label: false

      expected_all_href = project_labels_path(project)

      expect(rendered).to have_link('All', href: expected_all_href)
      expect(rendered).not_to have_link('Active')
      expect(rendered).not_to have_link('Archived')
    end
  end
end
