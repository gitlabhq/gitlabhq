# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::BatchedBackgroundOperation, feature_category: :database do
  let(:operation) { build_stubbed(:background_operation_worker, :active) }

  subject(:representation) { described_class.new(operation).as_json }

  it 'exposes the expected attributes' do
    expect(representation.keys).to match_array(%i[
      id
      partition
      job_class_name
      table_name
      column_name
      status
      created_at
      started_at
      finished_at
      on_hold_until
    ])
  end

  it 'exposes status as the state name' do
    expect(representation[:status]).to eq(:active)
  end
end
