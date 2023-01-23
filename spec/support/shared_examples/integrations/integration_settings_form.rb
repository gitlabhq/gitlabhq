# frozen_string_literal: true

RSpec.shared_examples 'integration settings form' do
  include IntegrationsHelper
  # Note: these specs don't validate channel fields
  # which are present on a few integrations
  it 'displays all the integrations' do
    aggregate_failures do
      integrations.each do |integration|
        stub_feature_flags(integration_slack_app_notifications: false)
        navigate_to_integration(integration)

        page.within('form.integration-settings-form') do
          expect(page).to have_field('Active', type: 'checkbox', wait: 0),
                          "#{integration.title} active field not present"

          fields = parse_json(fields_for_integration(integration))
          fields.each do |field|
            field_name = field[:name]
            expect(page).to have_field(field[:title], wait: 0),
                            "#{integration.title} field #{field_name} not present"
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

            expect(page).to have_field(trigger_title, type: 'checkbox', wait: 0),
                            "#{integration.title} field #{trigger_title} checkbox not present"
          end
        end
      end
    end
  end

  private

  def parse_json(json)
    Gitlab::Json.parse(json, symbolize_names: true)
  end

  def trigger_event_title(name)
    # Should match `integrationTriggerEventTitles` in app/assets/javascripts/integrations/constants.js
    event_titles = {
      push_events: s_('IntegrationEvents|A push is made to the repository'),
      issues_events: s_('IntegrationEvents|IntegrationEvents|An issue is created, updated, or closed'),
      confidential_issues_events: s_('IntegrationEvents|A confidential issue is created, updated, or closed'),
      merge_requests_events: s_('IntegrationEvents|A merge request is created, updated, or merged'),
      note_events: s_('IntegrationEvents|A comment is added on an issue'),
      confidential_note_events: s_('IntegrationEvents|A comment is added on a confidential issue'),
      tag_push_events: s_('IntegrationEvents|A tag is pushed to the repository'),
      pipeline_events: s_('IntegrationEvents|A pipeline status changes'),
      wiki_page_events: s_('IntegrationEvents|A wiki page is created or updated')
    }.with_indifferent_access
    event_titles[name]
  end
end
