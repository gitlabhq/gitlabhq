# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkPushEventPayloadService, feature_category: :source_code_management do
  let(:event) { create(:push_event) }

  let(:push_data) do
    {
      action: :created,
      ref_count: 4,
      ref_type: :branch
    }
  end

  subject { described_class.new(event, push_data) }

  it 'creates a PushEventPayload' do
    push_event_payload = subject.execute

    expect(push_event_payload).to be_persisted
    expect(push_event_payload.action).to eq(push_data[:action].to_s)
    expect(push_event_payload.commit_count).to eq(0)
    expect(push_event_payload.ref_count).to eq(push_data[:ref_count])
    expect(push_event_payload.ref_type).to eq(push_data[:ref_type].to_s)
  end
end
