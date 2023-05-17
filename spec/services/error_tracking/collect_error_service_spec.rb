# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::CollectErrorService, feature_category: :error_tracking do
  let_it_be(:project) { create(:project) }

  let(:parsed_event_file) { 'error_tracking/parsed_event.json' }
  let(:parsed_event) { parse_valid_event(parsed_event_file) }

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

      expect(event.description).to start_with 'Missing template posts/error2'
      expect(event.occurred_at).to eq '2021-07-08T12:59:16Z'
      expect(event.level).to eq 'error'
      expect(event.environment).to eq 'development'
      expect(event.payload).to eq parsed_event
    end

    context 'python sdk event' do
      let(:parsed_event_file) { 'error_tracking/python_event.json' }

      it 'creates a valid event' do
        expect { subject.execute }.to change { ErrorTracking::ErrorEvent.count }.by(1)
      end
    end

    context 'with unusual payload' do
      let(:event) { ErrorTracking::ErrorEvent.last! }

      context 'when transaction is missing' do
        it 'builds actor from stacktrace' do
          parsed_event.delete('transaction')

          subject.execute

          expect(event.error.actor).to eq 'find()'
        end
      end

      context 'when transaction is an empty string' do \
        it 'builds actor from stacktrace' do
          parsed_event['transaction'] = ''

          subject.execute

          expect(event.error.actor).to eq 'find()'
        end
      end

      context 'when timestamp is numeric' do
        it 'parses timestamp' do
          parsed_event['timestamp'] = '1631015580.50'

          subject.execute

          expect(event.occurred_at).to eq '2021-09-07T11:53:00.5'
        end
      end
    end

    context 'go payload' do
      let(:parsed_event_file) { 'error_tracking/go_parsed_event.json' }

      it 'has correct values set' do
        subject.execute

        event = ErrorTracking::ErrorEvent.last
        error = event.error

        expect(error.name).to eq '*errors.errorString'
        expect(error.description).to start_with 'Hello world'
        expect(error.platform).to eq 'go'

        expect(event.description).to start_with 'Hello world'
        expect(event.level).to eq 'error'
        expect(event.environment).to eq 'Accumulate'
        expect(event.payload).to eq parsed_event
      end

      context 'with two exceptions' do
        let(:parsed_event_file) { 'error_tracking/go_two_exception_event.json' }

        it 'reports using second exception', :aggregate_failures do
          subject.execute

          event = ErrorTracking::ErrorEvent.last
          error = event.error

          expect(error.name).to eq '*url.Error'
          expect(error.description).to eq(%(Get \"foobar\": unsupported protocol scheme \"\"))
          expect(error.platform).to eq 'go'
          expect(error.actor).to eq('main(main)')

          expect(event.description).to eq(%(Get \"foobar\": unsupported protocol scheme \"\"))
          expect(event.payload).to eq parsed_event
        end
      end
    end
  end

  private

  def parse_valid_event(parsed_event_file)
    parsed_event = Gitlab::Json.parse(fixture_file(parsed_event_file))

    validator = ErrorTracking::Collector::PayloadValidator.new
    # This a precondition for all specs to verify that
    # submitted JSON payload is valid.
    expect(validator).to be_valid(parsed_event)

    parsed_event
  end
end
