# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/sidebar/_project' do
  let_it_be_with_reload(:project) { create(:project, :repository) }

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

  describe 'Packages' do
    let(:user) { create(:user) }

    let_it_be(:package_menu_name) { 'Packages & Registries' }
    let_it_be(:package_entry_name) { 'Package Registry' }

    before do
      project.team.add_developer(user)
      sign_in(user)
      stub_container_registry_config(enabled: true)
    end

    context 'when packages is enabled' do
      it 'packages link is visible' do
        render

        expect(rendered).to have_link(package_menu_name, href: project_packages_path(project))
      end

      it 'packages list link is visible' do
        render

        expect(rendered).to have_link(package_entry_name, href: project_packages_path(project))
      end

      it 'container registry link is visible' do
        render

        expect(rendered).to have_link('Container Registry', href: project_container_registry_index_path(project))
      end
    end

    context 'when container registry is disabled' do
      before do
        stub_container_registry_config(enabled: false)
      end

      it 'packages top level and list link are visible' do
        render

        expect(rendered).to have_link(package_menu_name, href: project_packages_path(project))
        expect(rendered).to have_link(package_entry_name, href: project_packages_path(project))
      end

      it 'container registry link is not visible' do
        render

        expect(rendered).not_to have_link('Container Registry', href: project_container_registry_index_path(project))
      end
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

        expect(rendered).to have_link('Wiki', href: wiki_path(project.wiki))
      end
    end

    describe 'when wiki is disabled' do
      let(:can_read_wiki) { false }

      it 'does not show the wiki tab' do
        render

        expect(rendered).not_to have_link('Wiki')
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

        expect(rendered).not_to have_link('External Wiki')
      end
    end
  end

  describe 'confluence tab' do
    let!(:service) { create(:confluence_service, project: project, active: active) }

    before do
      render
    end

    context 'when the Confluence integration is active' do
      let(:active) { true }

      it 'shows the Confluence tab' do
        expect(rendered).to have_link('Confluence', href: project_wikis_confluence_path(project))
      end

      it 'does not show the GitLab wiki tab' do
        expect(rendered).not_to have_link('Wiki')
      end
    end

    context 'when it is disabled' do
      let(:active) { false }

      it 'does not show the Confluence tab' do
        expect(rendered).not_to have_link('Confluence')
      end

      it 'shows the GitLab wiki tab' do
        expect(rendered).to have_link('Wiki', href: wiki_path(project.wiki))
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

  describe 'pipeline editor link' do
    it 'shows the pipeline editor link' do
      render

      expect(rendered).to have_link('Editor', href: project_ci_pipeline_editor_path(project))
    end

    it 'does not show the pipeline editor link' do
      allow(view).to receive(:can_view_pipeline_editor?).and_return(false)

      render

      expect(rendered).not_to have_link('Editor', href: project_ci_pipeline_editor_path(project))
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

    describe 'Tracing' do
      it 'is not visible to unauthorized user' do
        allow(view).to receive(:can?).and_return(false)

        render

        expect(rendered).not_to have_text 'Tracing'
      end

      it 'links to Tracing page' do
        render

        expect(rendered).to have_link('Tracing', href: project_tracing_path(project))
      end

      context 'without project.tracing_external_url' do
        it 'links to Tracing page' do
          render

          expect(rendered).to have_link('Tracing', href: project_tracing_path(project))
        end
      end
    end

    describe 'Alert Management' do
      it 'shows the Alerts sidebar entry' do
        render

        expect(rendered).to have_css('a[title="Alerts"]')
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

  describe 'project access tokens' do
    context 'self-managed instance' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'displays "Access Tokens" nav item' do
        render

        expect(rendered).to have_link('Access Tokens', href: project_settings_access_tokens_path(project))
      end
    end

    context 'gitlab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'displays "Access Tokens" nav item' do
        render

        expect(rendered).to have_link('Access Tokens', href: project_settings_access_tokens_path(project))
      end
    end
  end
end
