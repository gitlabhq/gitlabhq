# frozen_string_literal: true

RSpec.shared_examples 'integration settings form' do
  include IntegrationsHelper
  # Note: these specs don't validate channel fields
  # which are present on a few integrations
  it 'displays all the integrations' do
    aggregate_failures do
      integrations.each do |integration|
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

          events = parse_json(trigger_events_for_integration(integration))
          events.each do |trigger|
            expect(page).to have_field(trigger[:title], type: 'checkbox', wait: 0),
                            "#{integration.title} field #{title} checkbox not present"
          end
        end
      end
    end
  end

  private

  def parse_json(json)
    Gitlab::Json.parse(json, symbolize_names: true)
  end
end
