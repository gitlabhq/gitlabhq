# frozen_string_literal: true

# Shared context for all integrations
#
# The following let binding should be defined:
# - `integration`: Integration name. See `Integration.available_integration_names`.
RSpec.shared_context 'with integration' do
  include Integrations::TestHelpers
  include JiraIntegrationHelpers

  let(:dashed_integration) { integration.dasherize }
  let(:integration_method) { Project.integration_association_name(integration) }
  let(:integration_klass) { Integration.integration_name_to_model(integration) }
  let(:integration_instance) { integration_klass.new }
  let(:integration_factory) { factory_for(integration_instance) }

  # Build a list of all attributes that an integration supports.
  let(:integration_attrs_list) do
    integration_fields + integration_events + custom_attributes.fetch(integration.to_sym, [])
  end

  # Attributes defined as fields.
  let(:integration_fields) do
    integration_instance.fields.map { |field| field[:name].to_sym }
  end

  # Attributes for configurable event triggers.
  let(:integration_events) do
    integration_instance.configurable_events
      .map { |event| IntegrationsHelper.integration_event_field_name(event).to_sym }
  end

  # Other special cases, this list might be incomplete.
  #
  # Some of these won't be needed anymore after we've converted them to use the field DSL
  # in https://gitlab.com/gitlab-org/gitlab/-/issues/354899.
  #
  # Others like `comment_on_event_disabled` are actual columns on `integrations`, maybe we should migrate
  # these to fields as well.
  let(:custom_attributes) do
    {
      jira: %i[
        comment_on_event_enabled jira_issue_transition_automatic jira_issue_transition_id project_key
        issues_enabled vulnerabilities_enabled vulnerabilities_issuetype
      ]
    }
  end

  let(:licensed_features) do
    {
      'github' => :github_integration
    }
  end

  before do
    enable_license_for_integration(integration)
    stub_jira_integration_test if integration == 'jira'
  end

  private

  def enable_license_for_integration(integration)
    return unless respond_to?(:stub_licensed_features)

    licensed_feature = licensed_features[integration]
    return unless licensed_feature

    stub_licensed_features(licensed_feature => true)
    project.clear_memoization(:disabled_integrations)
  end
end

RSpec.shared_context 'with integration activation' do
  def click_active_checkbox
    find('label', text: 'Active').click
  end
end
