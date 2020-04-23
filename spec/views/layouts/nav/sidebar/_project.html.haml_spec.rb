# frozen_string_literal: true

require 'spec_helper'

describe 'layouts/nav/sidebar/_project' do
  let(:project) { create(:project, :repository) }

  before do
    assign(:project, project)
    assign(:repository, project.repository)
    allow(view).to receive(:current_ref).and_return('master')

    allow(view).to receive(:can?).and_return(true)
  end

  it_behaves_like 'has nav sidebar'

  describe 'issue boards' do
    it 'has board tab' do
      render

      expect(rendered).to have_css('a[title="Boards"]')
    end
  end

  describe 'packages tab' do
    before do
      stub_container_registry_config(enabled: true)

      allow(controller).to receive(:controller_name)
        .and_return('repositories')
      allow(controller).to receive(:controller_path)
        .and_return('projects/registry/repositories')
    end

    it 'highlights sidebar item and flyout' do
      render

      expect(rendered).to have_css('.sidebar-top-level-items > li.active', count: 1)
      expect(rendered).to have_css('.sidebar-sub-level-items > li.fly-out-top-item.active', count: 1)
    end

    it 'highlights container registry tab' do
      render

      expect(rendered).to have_css('.sidebar-sub-level-items > li:not(.fly-out-top-item).active', text: 'Container Registry')
    end
  end

  describe 'releases entry' do
    it 'renders releases link' do
      render

      expect(rendered).to have_link('Releases', href: project_releases_path(project))
    end
  end

  describe 'wiki entry tab' do
    let(:can_read_wiki) { true }

    before do
      allow(view).to receive(:can?).with(nil, :read_wiki, project).and_return(can_read_wiki)
    end

    describe 'when wiki is enabled' do
      it 'shows the wiki tab with the wiki internal link' do
        render

        expect(rendered).to have_link('Wiki', href: project_wiki_path(project, :home))
      end
    end

    describe 'when wiki is disabled' do
      let(:can_read_wiki) { false }

      it 'does not show the wiki tab' do
        render

        expect(rendered).not_to have_link('Wiki', href: project_wiki_path(project, :home))
      end
    end
  end

  describe 'external wiki entry tab' do
    let(:properties) { { 'external_wiki_url' => 'https://gitlab.com' } }
    let(:service_status) { true }

    before do
      project.create_external_wiki_service(active: service_status, properties: properties)
      project.reload
    end

    context 'when it is active' do
      it 'shows the external wiki tab with the external wiki service link' do
        render

        expect(rendered).to have_link('External Wiki', href: properties['external_wiki_url'])
      end
    end

    context 'when it is disabled' do
      let(:service_status) { false }

      it 'does not show the external wiki tab' do
        render

        expect(rendered).not_to have_link('External Wiki', href: project_wiki_path(project, :home))
      end
    end
  end

  describe 'ci/cd settings tab' do
    before do
      project.update!(archived: project_archived)
    end

    context 'when project is archived' do
      let(:project_archived) { true }

      it 'does not show the ci/cd settings tab' do
        render

        expect(rendered).not_to have_link('CI / CD', href: project_settings_ci_cd_path(project))
      end
    end

    context 'when project is active' do
      let(:project_archived) { false }

      it 'shows the ci/cd settings tab' do
        render

        expect(rendered).to have_link('CI / CD', href: project_settings_ci_cd_path(project))
      end
    end
  end

  describe 'operations settings tab' do
    describe 'archive projects' do
      before do
        project.update!(archived: project_archived)
      end

      context 'when project is archived' do
        let(:project_archived) { true }

        it 'does not show the operations settings tab' do
          render

          expect(rendered).not_to have_link('Operations', href: project_settings_operations_path(project))
        end
      end

      context 'when project is active' do
        let(:project_archived) { false }

        it 'shows the operations settings tab' do
          render

          expect(rendered).to have_link('Operations', href: project_settings_operations_path(project))
        end
      end
    end

    describe 'Alert Management' do
      context 'when alert_management_minimal is enabled' do
        before do
          stub_feature_flags(alert_management_minimal: true)
        end

        it 'shows the Alerts sidebar entry' do
          render

          expect(rendered).to have_css('a[title="Alerts"]')
        end
      end

      context 'when alert_management_minimal is disabled' do
        before do
          stub_feature_flags(alert_management_minimal: false)
        end

        it 'does not show the Alerts sidebar entry' do
          render

          expect(rendered).to have_no_css('a[title="Alerts"]')
        end
      end
    end
  end

  describe 'value stream analytics entry' do
    let(:read_cycle_analytics) { true }

    before do
      allow(view).to receive(:can?).with(nil, :read_cycle_analytics, project).and_return(read_cycle_analytics)
    end

    describe 'when value stream analytics is enabled' do
      it 'shows the value stream analytics entry' do
        render

        expect(rendered).to have_link('Value Stream', href: project_cycle_analytics_path(project))
      end
    end

    describe 'when value stream analytics is disabled' do
      let(:read_cycle_analytics) { false }

      it 'does not show the value stream analytics entry' do
        render

        expect(rendered).not_to have_link('Value Stream', href: project_cycle_analytics_path(project))
      end
    end
  end
end
