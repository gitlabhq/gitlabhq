# frozen_string_literal: true

RSpec.shared_examples 'integration settings form' do
  include IntegrationsHelper

  before do
    stub_feature_flags(remove_monitor_metrics: false)
  end

  # Note: these specs don't validate channel fields
  # which are present on a few integrations
  it 'displays all the integrations', feature_category: :integrations do
    aggregate_failures do
      integrations.each do |integration|
        navigate_to_integration(integration)

        within_testid 'integration-settings-form' do
          if integration.manual_activation?
            expect(page).to have_field('Active', type: 'checkbox', wait: 0),
              "#{integration.title} active field not present #{page}"
          end

          fields = parse_json(fields_for_integration(integration))
          fields.each do |field|
            next if exclude_field?(integration, field)

            field_name = field[:name]

            if editable?(integration)
              expect(page).to have_field(field[:title], wait: 0),
                "#{integration.title} field #{field_name} not present"
            else
              expect(page).to have_field(field[:title], wait: 0, disabled: true),
                "#{integration.title} field #{field_name} not disabled"
            end
          end

          api_only_fields = integration.fields.select { _1[:api_only] }
          api_only_fields.each do |field|
            expect(page).not_to have_field("service[#{field.name}]", wait: 0)
          end

          sections = integration.sections
          events = parse_json(trigger_events_for_integration(integration))

          events.each do |trigger|
            trigger_title = if sections.any? { |s| s[:type] == 'trigger' }
                              trigger_event_title(trigger[:name])
                            else
                              trigger[:title]
                            end

            if editable?(integration)
              expect(page).to have_field(trigger_title, type: 'checkbox', wait: 0),
                "#{integration.title} field #{trigger_title} checkbox not present"
            else
              expect(page).to have_field(trigger_title, type: 'checkbox', wait: 0, disabled: true),
                "#{integration.title} field #{trigger_title} checkbox not disabled"
            end
          end
        end
      end
    end
  end

  private

  def parse_json(json)
    Gitlab::Json.parse(json, symbolize_names: true)
  end

  # Fields that have specific handling on the frontend
  def exclude_field?(integration, field)
    integration.is_a?(Integrations::Jira) && field[:name] == 'jira_auth_type'
  end

  # Some integrations are only editable when active, otherwise their fields are disabled
  def editable?(integration)
    integration.editable?
  end

  def trigger_event_title(name)
    # Should match `integrationTriggerEventTitles` in app/assets/javascripts/integrations/constants.js
    event_titles = {
      push_events: s_('IntegrationEvents|A push is made to the repository'),
      issues_events: s_('IntegrationEvents|An issue is created, closed, or reopened'),
      confidential_issues_events: s_('A confidential issue is created, closed, or reopened'),
      merge_requests_events: s_('IntegrationEvents|A merge request is created, merged, closed, or reopened'),
      note_events: s_('IntegrationEvents|A comment is added'),
      confidential_note_events: s_(
        'IntegrationEvents|An internal note or comment on a confidential issue is added'
      ),
      tag_push_events: s_('IntegrationEvents|A tag is pushed to the repository or removed'),
      pipeline_events: s_('IntegrationEvents|A pipeline status changes'),
      wiki_page_events: s_('IntegrationEvents|A wiki page is created or updated')
    }.with_indifferent_access
    event_titles[name]
  end
end
