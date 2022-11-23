# frozen_string_literal: true

require 'spec_helper'

# Requres:
#   * subject with a 'resolve' name
#   * Defined expected timeline event via `let(:expected_timeline_event) { instance_double(...) }`
RSpec.shared_examples 'creating an incident timeline event' do
  it 'creates a timeline event' do
    expect { resolve }.to change { IncidentManagement::TimelineEvent.count }.by(1)
  end

  it 'responds with a timeline event', :aggregate_failures do
    response = resolve
    timeline_event = IncidentManagement::TimelineEvent.last!

    expect(response).to match(timeline_event: timeline_event, errors: be_empty)

    expect(timeline_event.promoted_from_note).to eq(expected_timeline_event.promoted_from_note)
    expect(timeline_event.note).to eq(expected_timeline_event.note)
    expect(timeline_event.occurred_at.to_s).to eq(expected_timeline_event.occurred_at)
    expect(timeline_event.incident).to eq(expected_timeline_event.incident)
    expect(timeline_event.author).to eq(expected_timeline_event.author)
    expect(timeline_event.editable).to eq(expected_timeline_event.editable)
  end
end

# Requres
#   * subject with a 'resolve' name
#   * a user factory with a 'current_user' name
RSpec.shared_examples 'failing to create an incident timeline event' do
  context 'when a user has no permissions to create timeline event' do
    before do
      project.add_guest(current_user)
    end

    it 'raises an error' do
      expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end
end

# Requres:
#   * subject with a 'resolve' name
RSpec.shared_examples 'responding with an incident timeline errors' do |errors:|
  it 'returns errors' do
    expect(resolve).to eq(timeline_event: nil, errors: errors)
  end
end
