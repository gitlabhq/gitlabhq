# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/sidebar/_project' do
  let_it_be_with_reload(:project) { create(:project, :repository) }

  let(:user) { project.owner }
  let(:current_ref) { 'master' }

  before do
    assign(:project, project)
    assign(:repository, project.repository)

    allow(view).to receive(:current_ref).and_return(current_ref)
    allow(view).to receive(:can?).and_return(true)
    allow(view).to receive(:current_user).and_return(user)
  end

  it_behaves_like 'has nav sidebar'

  describe 'Project Overview' do
    it 'has a link to the project path' do
      render

      expect(rendered).to have_link('Project overview', href: project_path(project), class: %w(shortcuts-project rspec-project-link))
      expect(rendered).to have_selector('[aria-label="Project overview"]')
    end

    describe 'Details' do
      it 'has a link to the projects path' do
        render

        expect(rendered).to have_link('Details', href: project_path(project), class: 'shortcuts-project')
        expect(rendered).to have_selector('[aria-label="Project details"]')
      end
    end

    describe 'Activity' do
      it 'has a link to the project activity path' do
        render

        expect(rendered).to have_link('Activity', href: activity_project_path(project), class: 'shortcuts-project-activity')
      end
    end

    describe 'Releases' do
      it 'has a link to the project releases path' do
        render

        expect(rendered).to have_link('Releases', href: project_releases_path(project), class: 'shortcuts-project-releases')
      end
    end
  end

  describe 'Learn GitLab' do
    it 'has a link to the learn GitLab experiment' do
      allow(view).to receive(:learn_gitlab_experiment_enabled?).and_return(true)
      allow_next_instance_of(LearnGitlab::Onboarding) do |onboarding|
        expect(onboarding).to receive(:completed_percentage).and_return(20)
      end

      render

      expect(rendered).to have_link('Learn GitLab', href: project_learn_gitlab_path(project))
    end
  end

  describe 'Repository' do
    it 'has a link to the project tree path' do
      render

      expect(rendered).to have_link('Repository', href: project_tree_path(project, current_ref), class: 'shortcuts-tree')
    end

    describe 'Files' do
      it 'has a link to the project tree path' do
        render

        expect(rendered).to have_link('Files', href: project_tree_path(project, current_ref))
      end
    end

    describe 'Commits' do
      it 'has a link to the project commits path' do
        render

        expect(rendered).to have_link('Commits', href: project_commits_path(project, current_ref), id: 'js-onboarding-commits-link')
      end
    end

    describe 'Branches' do
      it 'has a link to the project branches path' do
        render

        expect(rendered).to have_link('Branches', href: project_branches_path(project), id: 'js-onboarding-branches-link')
      end
    end

    describe 'Tags' do
      it 'has a link to the project tags path' do
        render

        expect(rendered).to have_link('Tags', href: project_tags_path(project))
      end
    end

    describe 'Contributors' do
      it 'has a link to the project contributors path' do
        render

        expect(rendered).to have_link('Contributors', href: project_graph_path(project, current_ref))
      end
    end

    describe 'Graph' do
      it 'has a link to the project graph path' do
        render

        expect(rendered).to have_link('Graph', href: project_network_path(project, current_ref))
      end
    end

    describe 'Compare' do
      it 'has a link to the project compare path' do
        render

        expect(rendered).to have_link('Compare', href: project_compare_index_path(project, from: project.repository.root_ref, to: current_ref))
      end
    end
  end

  describe 'Issues' do
    it 'has a link to the issue list path' do
      render

      expect(rendered).to have_link('Issues', href: project_issues_path(project))
    end

    it 'shows pill with the number of open issues' do
      render

      expect(rendered).to have_css('span.badge.badge-pill.issue_counter')
    end

    describe 'Issue List' do
      it 'has a link to the issue list path' do
        render

        expect(rendered).to have_link('List', href: project_issues_path(project))
      end
    end

    describe 'Issue Boards' do
      it 'has a link to the issue boards path' do
        render

        expect(rendered).to have_link('Boards', href: project_boards_path(project))
      end
    end

    describe 'Labels' do
      it 'has a link to the labels path' do
        render

        expect(rendered).to have_link('Labels', href: project_labels_path(project))
      end
    end

    describe 'Service Desk' do
      it 'has a link to the service desk path' do
        render

        expect(rendered).to have_link('Service Desk', href: service_desk_project_issues_path(project))
      end
    end

    describe 'Milestones' do
      it 'has a link to the milestones path' do
        render

        expect(rendered).to have_link('Milestones', href: project_milestones_path(project))
      end
    end
  end

  describe 'External Issue Tracker' do
    let_it_be_with_refind(:project) { create(:project, has_external_issue_tracker: true) }

    context 'with custom external issue tracker' do
      let(:external_issue_tracker_url) { 'http://test.com' }

      let!(:external_issue_tracker) do
        create(:custom_issue_tracker_service, active: external_issue_tracker_active, project: project, project_url: external_issue_tracker_url)
      end

      context 'when external issue tracker is configured and active' do
        let(:external_issue_tracker_active) { true }

        it 'has a link to the external issue tracker' do
          render

          expect(rendered).to have_link(external_issue_tracker.title, href: external_issue_tracker_url)
        end
      end

      context 'when external issue tracker is not configured and active' do
        let(:external_issue_tracker_active) { false }

        it 'does not have a link to the external issue tracker' do
          render

          expect(rendered).not_to have_link(external_issue_tracker.title)
        end
      end
    end

    context 'with Jira issue tracker' do
      let_it_be(:jira) { create(:jira_service, project: project, issues_enabled: false) }

      it 'has a link to the Jira issue tracker' do
        render

        expect(rendered).to have_link('Jira', href: project.external_issue_tracker.issue_tracker_path)
      end
    end
  end

  describe 'Labels' do
    context 'when issues are not enabled' do
      it 'has a link to the labels path' do
        project.project_feature.update!(issues_access_level: ProjectFeature::DISABLED)

        render

        expect(rendered).to have_link('Labels', href: project_labels_path(project), class: 'shortcuts-labels')
      end
    end

    context 'when issues are enabled' do
      it 'does not have a link to the labels path' do
        render

        expect(rendered).not_to have_link('Labels', href: project_labels_path(project), class: 'shortcuts-labels')
      end
    end
  end

  describe 'Merge Requests' do
    it 'has a link to the merge request list path' do
      render

      expect(rendered).to have_link('Merge requests', href: project_merge_requests_path(project), class: 'shortcuts-merge_requests')
    end

    it 'shows pill with the number of merge requests' do
      render

      expect(rendered).to have_css('span.badge.badge-pill.merge_counter.js-merge-counter')
    end
  end

  describe 'CI/CD' do
    it 'has a link to pipelines page' do
      render

      expect(rendered).to have_link('CI/CD', href: project_pipelines_path(project))
    end

    describe 'Artifacts' do
      it 'has a link to the artifacts page' do
        render

        expect(rendered).to have_link('Artifacts', href: project_artifacts_path(project))
      end
    end

    describe 'Jobs' do
      it 'has a link to the jobs page' do
        render

        expect(rendered).to have_link('Jobs', href: project_jobs_path(project))
      end
    end

    describe 'Pipeline Schedules' do
      it 'has a link to the pipeline schedules page' do
        render

        expect(rendered).to have_link('Schedules', href: pipeline_schedules_path(project))
      end
    end

    describe 'Pipelines' do
      it 'has a link to the pipelines page' do
        render

        expect(rendered).to have_link('Pipelines', href: project_pipelines_path(project))
      end
    end

    describe 'Pipeline Editor' do
      it 'has a link to the pipeline editor' do
        render

        expect(rendered).to have_link('Editor', href: project_ci_pipeline_editor_path(project))
      end

      context 'when user cannot access pipeline editor' do
        it 'does not has a link to the pipeline editor' do
          allow(view).to receive(:can_view_pipeline_editor?).and_return(false)

          render

          expect(rendered).not_to have_link('Editor', href: project_ci_pipeline_editor_path(project))
        end
      end
    end
  end

  describe 'Security and Compliance' do
    describe 'when user does not have permissions' do
      before do
        allow(view).to receive(:current_user).and_return(nil)
      end

      it 'top level navigation link is not visible' do
        render

        expect(rendered).not_to have_link('Security & Compliance')
      end
    end

    context 'when user has permissions' do
      before do
        allow(view).to receive(:current_user).and_return(user)

        render
      end

      it 'top level navigation link is visible' do
        expect(rendered).to have_link('Security & Compliance')
      end

      it 'security configuration link is visible' do
        expect(rendered).to have_link('Configuration', href: project_security_configuration_path(project))
      end
    end
  end

  describe 'Operations' do
    it 'top level navigation link is visible for user with permissions' do
      render

      expect(rendered).to have_link('Operations')
    end

    describe 'Metrics Dashboard' do
      it 'has a link to the metrics dashboard page' do
        render

        expect(rendered).to have_link('Metrics', href: project_metrics_dashboard_path(project))
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the metrics page' do
          render

          expect(rendered).not_to have_link('Metrics')
        end
      end
    end

    describe 'Logs' do
      it 'has a link to the pod logs page' do
        render

        expect(rendered).to have_link('Logs', href: project_logs_path(project))
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the pod logs page' do
          render

          expect(rendered).not_to have_link('Logs')
        end
      end
    end

    describe 'Tracing' do
      it 'has a link to the tracing page' do
        render

        expect(rendered).to have_link('Tracing', href: project_tracing_path(project))
      end

      context 'without project.tracing_external_url' do
        it 'has a link to the tracing page' do
          render

          expect(rendered).to have_link('Tracing', href: project_tracing_path(project))
        end
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the tracing page' do
          render

          expect(rendered).not_to have_text 'Tracing'
        end
      end
    end

    describe 'Error Tracking' do
      it 'has a link to the error tracking page' do
        render

        expect(rendered).to have_link('Error Tracking', href: project_error_tracking_index_path(project))
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the error tracking page' do
          render

          expect(rendered).not_to have_link('Error Tracking')
        end
      end
    end

    describe 'Alert Management' do
      it 'has a link to the alert management page' do
        render

        expect(rendered).to have_link('Alerts', href: project_alert_management_index_path(project))
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the alert management page' do
          render

          expect(rendered).not_to have_link('Alerts')
        end
      end
    end

    describe 'Incidents' do
      it 'has a link to the incidents page' do
        render

        expect(rendered).to have_link('Incidents', href: project_incidents_path(project))
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the incidents page' do
          render

          expect(rendered).not_to have_link('Incidents')
        end
      end
    end

    describe 'Serverless' do
      it 'has a link to the serverless page' do
        render

        expect(rendered).to have_link('Serverless', href: project_serverless_functions_path(project))
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the serverless page' do
          render

          expect(rendered).not_to have_link('Serverless')
        end
      end
    end

    describe 'Terraform' do
      it 'has a link to the terraform page' do
        render

        expect(rendered).to have_link('Terraform', href: project_terraform_index_path(project))
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the terraform page' do
          render

          expect(rendered).not_to have_link('Terraform')
        end
      end
    end

    describe 'Kubernetes' do
      it 'has a link to the kubernetes page' do
        render

        expect(rendered).to have_link('Kubernetes', href: project_clusters_path(project))
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the kubernetes page' do
          render

          expect(rendered).not_to have_link('Kubernetes')
        end
      end
    end

    describe 'Environments' do
      it 'has a link to the environments page' do
        render

        expect(rendered).to have_link('Environments', href: project_environments_path(project))
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the environments page' do
          render

          expect(rendered).not_to have_link('Environments')
        end
      end
    end

    describe 'Feature Flags' do
      it 'has a link to the feature flags page' do
        render

        expect(rendered).to have_link('Feature Flags', href: project_feature_flags_path(project))
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the feature flags page' do
          render

          expect(rendered).not_to have_link('Feature Flags')
        end
      end
    end

    describe 'Product Analytics' do
      it 'has a link to the product analytics page' do
        render

        expect(rendered).to have_link('Product Analytics', href: project_product_analytics_path(project))
      end

      describe 'when feature flag :product_analytics is disabled' do
        it 'does not have a link to the feature flags page' do
          stub_feature_flags(product_analytics: false)

          render

          expect(rendered).not_to have_link('Product Analytics')
        end
      end
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
    let_it_be(:user) { create(:user) }

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

  describe 'wiki entry tab' do
    let(:can_read_wiki) { true }

    before do
      allow(view).to receive(:can?).with(user, :read_wiki, project).and_return(can_read_wiki)
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

        expect(rendered).to have_link('External wiki', href: properties['external_wiki_url'])
      end
    end

    context 'when it is disabled' do
      let(:service_status) { false }

      it 'does not show the external wiki tab' do
        render

        expect(rendered).not_to have_link('External wiki')
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

  describe 'value stream analytics entry' do
    let(:read_cycle_analytics) { true }

    before do
      allow(view).to receive(:can?).with(user, :read_cycle_analytics, project).and_return(read_cycle_analytics)
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

  it_behaves_like 'sidebar includes snowplow attributes', 'render', 'projects_side_navigation', 'projects_side_navigation'
end
