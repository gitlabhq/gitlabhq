# frozen_string_literal: true

require 'fast_spec_helper'

KNOWN_STABLE_CE_IDS = %i[
  access_tokens
  achievements
  active_sessions
  activity
  admin_appearance
  admin_ci_cd
  admin_integrations
  admin_metrics
  admin_network
  admin_preferences
  admin_reporting
  admin_repository
  alert_management
  alerts
  api_keys
  api_monitoring
  applications
  artifacts
  attestations
  authentication_log
  aws
  background_jobs
  background_migrations
  boards
  branches
  ci_cd
  ci_cd_analytics
  cloudseed_aws
  commits
  compare
  configuration
  confluence
  container_registry
  contributors
  crm_contacts
  cycle_analytics
  dashboard
  database_diagnostics
  dependency_proxy
  dev_ops_reports
  environments
  error_tracking
  exceptions
  external_issue_tracker
  external_wiki
  feature_flags
  files
  general
  general_settings
  gitaly_servers
  google_cloud
  gpg_keys
  graph
  graphs
  group_issue_list
  group_kubernetes_clusters
  group_merge_request_list
  group_overview
  groups
  harbor_registry
  health_check
  incidents
  incubation_5mp_google_cloud
  infrastructure_monitoring
  infrastructure_registry
  integrations
  issue_boards
  issue_list
  jobs
  kubernetes
  labels
  logs_explorer
  members
  messaging_queues
  metrics_dashboard
  metrics_explorer
  milestones
  model_experiments
  model_registry
  monitor
  new_issue
  notification_channels
  o11y_settings
  organization_overview
  organization_settings_general
  organization_users
  organizations
  packages_and_registries
  packages_registry
  pages
  password_and_authentication
  pipeline_schedules
  pipelines
  pipelines_editor
  project_issue_list
  project_merge_request_list
  project_overview
  project_snippets
  project_wiki
  projects
  releases
  repository
  repository_analytics
  runners
  search
  service_accounts
  service_desk
  service_map
  services
  setup
  ssh_keys
  system_info
  tags
  terraform_states
  topics
  traces_explorer
  usage_quotas
  usage_trends
  users
  webhooks
].freeze

KNOWN_STABLE_EE_IDS = %i[
  agents_onboarding
  agents_runs
  ai_agents
  ai_catalog_agents
  ai_catalog_mcp_servers
  ai_flow_triggers
  ai_flows
  audit_events
  compliance
  contribution_analytics
  credentials
  dependency_list
  devops_adoption
  epic_list
  geo_nodes
  geo_settings
  get_started
  group_epic_list
  group_wiki
  insights
  issues_analytics
  learn_gitlab
  productivity_analytics
  roadmap
  scan_policies
  secrets_manager
  security_dashboard
  security_dashboard_menu
  security_inventory
  security_settings
  deploy_applications
  deploy_environments
  vulnerability_report
].freeze

RSpec.describe 'Nav item ID stability', feature_category: :navigation do
  let(:sidebar_source_ids) do
    files = Rails.root.glob('lib/sidebars/**/*.rb')
    files += Rails.root.glob('ee/lib/sidebars/**/*.rb') if Gitlab.ee?

    files.flat_map { |path| File.read(path).scan(/\bitem_id:\s+:([a-z_0-9]+)/).flatten }
         .map(&:to_sym)
         .uniq
  end

  it 'has a complete and stable set of nav item IDs' do
    expected = Gitlab.ee? ? KNOWN_STABLE_CE_IDS + KNOWN_STABLE_EE_IDS : KNOWN_STABLE_CE_IDS

    expect(sidebar_source_ids.sort).to eq(expected.sort)
  end
end
