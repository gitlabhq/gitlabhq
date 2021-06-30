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

  describe 'Project context' do
    it 'has a link to the project path' do
      render

      expect(rendered).to have_link(project.name, href: project_path(project), class: %w(shortcuts-project rspec-project-link))
      expect(rendered).to have_selector("[aria-label=\"#{project.name}\"]")
    end
  end

  describe 'Project information' do
    it 'has a link to the project activity path' do
      render

      expect(rendered).to have_link('Project information', href: activity_project_path(project), class: %w(shortcuts-project-information))
      expect(rendered).to have_selector('[aria-label="Project information"]')
    end

    describe 'Activity' do
      it 'has a link to the project activity path' do
        render

        expect(rendered).to have_link('Activity', href: activity_project_path(project), class: 'shortcuts-project-activity')
      end
    end

    describe 'Labels' do
      let(:page) { Nokogiri::HTML.parse(rendered) }

      it 'has a link to the labels path' do
        render

        expect(page.at_css('.shortcuts-project-information').parent.css('[aria-label="Labels"]')).not_to be_empty
        expect(rendered).to have_link('Labels', href: project_labels_path(project))
      end
    end

    describe 'Members' do
      let(:page) { Nokogiri::HTML.parse(rendered) }

      it 'has a link to the members page' do
        render

        expect(page.at_css('.shortcuts-project-information').parent.css('[aria-label="Members"]')).not_to be_empty
        expect(rendered).to have_link('Members', href: project_project_members_path(project))
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
        create(:custom_issue_tracker_integration, active: external_issue_tracker_active, project: project, project_url: external_issue_tracker_url)
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
      let_it_be(:jira) { create(:jira_integration, project: project, issues_enabled: false) }

      it 'has a link to the Jira issue tracker' do
        render

        expect(rendered).to have_link('Jira', href: project.external_issue_tracker.issue_tracker_path)
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

  describe 'Deployments' do
    let(:page) { Nokogiri::HTML.parse(rendered) }

    describe 'Feature Flags' do
      it 'has a link to the feature flags page' do
        render

        expect(page.at_css('.shortcuts-deployments').parent.css('[aria-label="Feature Flags"]')).not_to be_empty
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

    describe 'Environments' do
      it 'has a link to the environments page' do
        render

        expect(page.at_css('.shortcuts-deployments').parent.css('[aria-label="Environments"]')).not_to be_empty
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

    describe 'Releases' do
      it 'has a link to the project releases path' do
        render

        expect(rendered).to have_link('Releases', href: project_releases_path(project), class: 'shortcuts-deployments-releases')
      end
    end
  end

  describe 'Monitor' do
    it 'top level navigation link is visible for user with permissions' do
      render

      expect(rendered).to have_link('Monitor')
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

  describe 'Infrastructure' do
    describe 'Serverless platform' do
      it 'has a link to the serverless page' do
        render

        expect(rendered).to have_link('Serverless platform', href: project_serverless_functions_path(project))
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the serverless page' do
          render

          expect(rendered).not_to have_link('Serverless platform')
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

    describe 'Kubernetes clusters' do
      it 'has a link to the kubernetes page' do
        render

        expect(rendered).to have_link('Kubernetes clusters', href: project_clusters_path(project))
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the kubernetes page' do
          render

          expect(rendered).not_to have_link('Kubernetes clusters')
        end
      end
    end
  end

  describe 'Packages and Registries' do
    let(:registry_enabled) { true }
    let(:packages_enabled) { true }

    before do
      stub_container_registry_config(enabled: registry_enabled)
      stub_config(packages: { enabled: packages_enabled })
    end

    it 'top level navigation link is visible and points to package registry page' do
      render

      expect(rendered).to have_link('Packages & Registries', href: project_packages_path(project))
    end

    describe 'Packages Registry' do
      it 'shows link to package registry page' do
        render

        expect(rendered).to have_link('Package Registry', href: project_packages_path(project))
      end

      context 'when packages config setting is not enabled' do
        let(:packages_enabled) { false }

        it 'does not show link to package registry page' do
          render

          expect(rendered).not_to have_link('Package Registry', href: project_packages_path(project))
        end
      end
    end

    describe 'Container Registry' do
      it 'shows link to container registry page' do
        render

        expect(rendered).to have_link('Container Registry', href: project_container_registry_index_path(project))
      end

      context 'when container config setting is not enabled' do
        let(:registry_enabled) { false }

        it 'does not show link to package registry page' do
          render

          expect(rendered).not_to have_link('Container Registry', href: project_container_registry_index_path(project))
        end
      end
    end

    describe 'Infrastructure Registry' do
      it 'shows link to infrastructure registry page' do
        render

        expect(rendered).to have_link('Infrastructure Registry', href: project_infrastructure_registry_index_path(project))
      end

      context 'when feature flag :infrastructure_registry_page is disabled' do
        it 'does not show link to package registry page' do
          stub_feature_flags(infrastructure_registry_page: false)

          render

          expect(rendered).not_to have_link('Infrastructure Registry', href: project_infrastructure_registry_index_path(project))
        end
      end
    end
  end

  describe 'Analytics' do
    it 'top level navigation link is visible points to the value stream page' do
      render

      expect(rendered).to have_link('Analytics', href: project_cycle_analytics_path(project))
    end

    describe 'CI/CD' do
      it 'has a link to the CI/CD analytics page' do
        render

        expect(rendered).to have_link('CI/CD', href: charts_project_pipelines_path(project))
      end

      context 'when user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the CI/CD analytics page' do
          render

          expect(rendered).not_to have_link('CI/CD', href: charts_project_pipelines_path(project))
        end
      end
    end

    describe 'Repository' do
      it 'has a link to the repository analytics page' do
        render

        expect(rendered).to have_link('Repository', href: charts_project_graph_path(project, 'master'))
      end

      context 'when user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the repository analytics page' do
          render

          expect(rendered).not_to have_link('Repository', href: charts_project_graph_path(project, 'master'))
        end
      end
    end

    describe 'Value stream' do
      it 'has a link to the value stream page' do
        render

        expect(rendered).to have_link('Value stream', href: project_cycle_analytics_path(project))
      end

      context 'when user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the value stream page' do
          render

          expect(rendered).not_to have_link('Value stream', href: project_cycle_analytics_path(project))
        end
      end
    end
  end

  describe 'Confluence' do
    let!(:service) { create(:confluence_integration, project: project, active: active) }

    before do
      render
    end

    context 'when the Confluence integration is active' do
      let(:active) { true }

      it 'shows the Confluence link' do
        expect(rendered).to have_link('Confluence', href: project_wikis_confluence_path(project))
      end

      it 'does not show the GitLab wiki link' do
        expect(rendered).not_to have_link('Wiki')
      end
    end

    context 'when it is disabled' do
      let(:active) { false }

      it 'does not show the Confluence link' do
        expect(rendered).not_to have_link('Confluence')
      end

      it 'shows the GitLab wiki link' do
        expect(rendered).to have_link('Wiki', href: wiki_path(project.wiki))
      end
    end
  end

  describe 'Wiki' do
    describe 'when wiki is enabled' do
      it 'shows the wiki tab with the wiki internal link' do
        render

        expect(rendered).to have_link('Wiki', href: wiki_path(project.wiki))
      end
    end

    describe 'when wiki is disabled' do
      let(:user) { nil }

      it 'does not show the wiki link' do
        render

        expect(rendered).not_to have_link('Wiki')
      end
    end
  end

  describe 'External Wiki' do
    let(:properties) { { 'external_wiki_url' => 'https://gitlab.com' } }
    let(:service_status) { true }

    before do
      project.create_external_wiki_integration(active: service_status, properties: properties)
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

      it 'does not show the external wiki link' do
        render

        expect(rendered).not_to have_link('External wiki')
      end
    end
  end

  describe 'Snippets' do
    before do
      render
    end

    context 'when user can access snippets' do
      it 'shows Snippets link' do
        expect(rendered).to have_link('Snippets', href: project_snippets_path(project))
      end
    end

    context 'when user cannot access snippets' do
      let(:user) { nil }

      it 'does not show Snippets link' do
        expect(rendered).not_to have_link('Snippets')
      end
    end
  end

  describe 'Settings' do
    describe 'General' do
      it 'has a link to the General settings' do
        render

        expect(rendered).to have_link('General', href: edit_project_path(project))
      end
    end

    describe 'Integrations' do
      it 'has a link to the Integrations settings' do
        render

        expect(rendered).to have_link('Integrations', href: project_settings_integrations_path(project))
      end
    end

    describe 'WebHooks' do
      it 'has a link to the WebHooks settings' do
        render

        expect(rendered).to have_link('Webhooks', href: project_hooks_path(project))
      end
    end

    describe 'Access Tokens' do
      context 'self-managed instance' do
        before do
          allow(Gitlab).to receive(:com?).and_return(false)
        end

        it 'has a link to the Access Tokens settings' do
          render

          expect(rendered).to have_link('Access Tokens', href: project_settings_access_tokens_path(project))
        end
      end

      context 'gitlab.com' do
        before do
          allow(Gitlab).to receive(:com?).and_return(true)
        end

        it 'has a link to the Access Tokens settings' do
          render

          expect(rendered).to have_link('Access Tokens', href: project_settings_access_tokens_path(project))
        end
      end
    end

    describe 'Repository' do
      it 'has a link to the Repository settings' do
        render

        expect(rendered).to have_link('Repository', href: project_settings_repository_path(project))
      end
    end

    describe 'CI/CD' do
      context 'when project is archived' do
        before do
          project.update!(archived: true)
        end

        it 'does not have a link to the CI/CD settings' do
          render

          expect(rendered).not_to have_link('CI/CD', href: project_settings_ci_cd_path(project))
        end
      end

      context 'when project is not archived' do
        it 'has a link to the CI/CD settings' do
          render

          expect(rendered).to have_link('CI/CD', href: project_settings_ci_cd_path(project))
        end
      end
    end

    describe 'Monitor' do
      context 'when project is archived' do
        before do
          project.update!(archived: true)
        end

        it 'does not have a link to the Monitor settings' do
          render

          expect(rendered).not_to have_link('Monitor', href: project_settings_operations_path(project))
        end
      end

      context 'when project is not archived active' do
        it 'has a link to the Monitor settings' do
          render

          expect(rendered).to have_link('Monitor', href: project_settings_operations_path(project))
        end
      end
    end

    describe 'Pages' do
      before do
        stub_config(pages: { enabled: pages_enabled })
      end

      context 'when pages are enabled' do
        let(:pages_enabled) { true }

        it 'has a link to the Pages settings' do
          render

          expect(rendered).to have_link('Pages', href: project_pages_path(project))
        end
      end

      context 'when pages are not enabled' do
        let(:pages_enabled) { false }

        it 'does not have a link to the Pages settings' do
          render

          expect(rendered).not_to have_link('Pages', href: project_pages_path(project))
        end
      end
    end

    describe 'Packages & Registries' do
      before do
        stub_container_registry_config(enabled: registry_enabled)
      end

      context 'when registry is enabled' do
        let(:registry_enabled) { true }

        it 'has a link to the Packages & Registries settings' do
          render

          expect(rendered).to have_link('Packages & Registries', href: project_settings_packages_and_registries_path(project))
        end
      end

      context 'when registry is not enabled' do
        let(:registry_enabled) { false }

        it 'does not have a link to the Packages & Registries settings' do
          render

          expect(rendered).not_to have_link('Packages & Registries', href: project_settings_packages_and_registries_path(project))
        end
      end
    end
  end

  describe 'Hidden menus' do
    it 'has a link to the Activity page' do
      render

      expect(rendered).to have_link('Activity', href: activity_project_path(project), class: 'shortcuts-project-activity', visible: false)
    end

    it 'has a link to the Graph page' do
      render

      expect(rendered).to have_link('Graph', href: project_network_path(project, current_ref), class: 'shortcuts-network', visible: false)
    end

    it 'has a link to the New Issue page' do
      render

      expect(rendered).to have_link('Create a new issue', href: new_project_issue_path(project), class: 'shortcuts-new-issue', visible: false)
    end

    it 'has a link to the Jobs page' do
      render

      expect(rendered).to have_link('Jobs', href: project_jobs_path(project), class: 'shortcuts-builds', visible: false)
    end

    it 'has a link to the Commits page' do
      render

      expect(rendered).to have_link('Commits', href: project_commits_path(project), class: 'shortcuts-commits', visible: false)
    end

    it 'has a link to the Issue Boards page' do
      render

      expect(rendered).to have_link('Issue Boards', href: project_boards_path(project), class: 'shortcuts-issue-boards', visible: false)
    end
  end

  it_behaves_like 'sidebar includes snowplow attributes', 'render', 'projects_side_navigation', 'projects_side_navigation'

  describe 'Collapsed menu items' do
    it 'does not render the collapsed top menu as a link' do
      render

      expect(rendered).not_to have_selector('.sidebar-sub-level-items > li.fly-out-top-item > a')
    end
  end
end
