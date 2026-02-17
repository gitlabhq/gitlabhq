# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundOperation::Observability::Events::Event, feature_category: :database do
  subject(:event) { described_class.new(record, **attributes) }

  let(:record_class) { class_double(Gitlab::Database::BackgroundOperation::Worker, name: 'Worker') }
  let(:attributes) { { key: 'value' } }
  let(:payload) { { message: 'test_payload' } }
  let(:record) do
    instance_double(
      Gitlab::Database::BackgroundOperation::Worker,
      id: [1, 100],
      min_cursor: [10],
      max_cursor: [50],
      created_at: '2026-01-21 16:00:00 UTC',
      started_at: '2026-01-22 16:30:00 UTC',
      finished_at: '2026-01-22 16:35:00 UTC'
    )
  end

  before do
    allow(record).to receive(:class).and_return(record_class)
    allow(event).to receive(:payload).and_return(payload)
  end

  describe '#log' do
    it 'logs payload merged with shared_payload' do
      expect(Gitlab::AppLogger).to(
        receive(:info).with(
          hash_including(
            message: 'test_payload',
            id: 100,
            partition: 1,
            record_type: 'Worker',
            created_at: '2026-01-21 16:00:00 UTC',
            started_at: '2026-01-22 16:30:00 UTC',
            finished_at: '2026-01-22 16:35:00 UTC'
          )
        )
      )

      event.log
    end
  end
end
