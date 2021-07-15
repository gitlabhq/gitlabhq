# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::CollectErrorService do
  let_it_be(:project) { create(:project) }
  let_it_be(:parsed_event) { Gitlab::Json.parse(fixture_file('error_tracking/parsed_event.json')) }

  subject { described_class.new(project, nil, event: parsed_event) }

  describe '#execute' do
    it 'creates Error and creates ErrorEvent' do
      expect { subject.execute }
        .to change { ErrorTracking::Error.count }.by(1)
        .and change { ErrorTracking::ErrorEvent.count }.by(1)
    end

    it 'updates Error and created ErrorEvent on second hit' do
      subject.execute

      expect { subject.execute }.not_to change { ErrorTracking::Error.count }
      expect { subject.execute }.to change { ErrorTracking::ErrorEvent.count }.by(1)
    end

    it 'has correct values set' do
      subject.execute

      event = ErrorTracking::ErrorEvent.last
      error = event.error

      expect(error.name).to eq 'ActionView::MissingTemplate'
      expect(error.description).to start_with 'Missing template posts/error2'
      expect(error.actor).to eq 'PostsController#error2'
      expect(error.platform).to eq 'ruby'
      expect(error.last_seen_at).to eq '2021-07-08T12:59:16Z'

      expect(event.description).to eq 'ActionView::MissingTemplate'
      expect(event.occurred_at).to eq '2021-07-08T12:59:16Z'
      expect(event.level).to eq 'error'
      expect(event.environment).to eq 'development'
      expect(event.payload).to eq parsed_event
    end
  end
end
