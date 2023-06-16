# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ErrorTracking::ErrorRepository::OpenApiStrategy do
  include AfterNextHelpers

  let(:project) { build_stubbed(:project) }
  let(:api_exception) { ErrorTrackingOpenAPI::ApiError.new(code: 500, response_body: 'b' * 101) }

  subject(:repository) { Gitlab::ErrorTracking::ErrorRepository.build(project) }

  before do
    # Disabled in spec_helper by default thus we need to enable it here.
    stub_feature_flags(gitlab_error_tracking: true)
  end

  shared_examples 'exception logging' do
    it 'logs error' do
      expect(Gitlab::AppLogger).to receive(:error).with({
        'open_api.http_code' => api_exception.code,
        'open_api.response_body' => api_exception.response_body.truncate(100)
      })

      subject
    end
  end

  shared_examples 'no logging' do
    it 'does not log anything' do
      expect(Gitlab::AppLogger).not_to receive(:debug)
      expect(Gitlab::AppLogger).not_to receive(:info)
      expect(Gitlab::AppLogger).not_to receive(:error)
    end
  end

  describe '#report_error' do
    let(:params) do
      {
        name: 'anything',
        description: 'anything',
        actor: 'anything',
        platform: 'anything',
        environment: 'anything',
        level: 'anything',
        occurred_at: Time.zone.now,
        payload: {}
      }
    end

    subject { repository.report_error(**params) }

    it 'is not implemented' do
      expect { subject }.to raise_error(NotImplementedError, 'Use ingestion endpoint')
    end
  end

  describe '#find_error' do
    let(:error) { build(:error_tracking_open_api_error, project_id: project.id) }

    subject { repository.find_error(error.fingerprint) }

    before do
      allow_next_instance_of(ErrorTrackingOpenAPI::ErrorsApi) do |open_api|
        allow(open_api).to receive(:get_error).with(project.id, error.fingerprint)
          .and_return(error)

        allow(open_api).to receive(:list_events)
          .with(project.id, error.fingerprint, { sort: 'occurred_at_asc', limit: 1 })
          .and_return(list_events_asc)

        allow(open_api).to receive(:list_events)
          .with(project.id, error.fingerprint, { sort: 'occurred_at_desc', limit: 1 })
          .and_return(list_events_desc)
      end
    end

    context 'when request succeeds' do
      context 'without events returned' do
        let(:list_events_asc) { [] }
        let(:list_events_desc) { [] }

        include_examples 'no logging'

        it 'returns detailed error' do
          is_expected.to have_attributes(
            id: error.fingerprint.to_s,
            title: "#{error.name}: #{error.description}",
            message: error.description,
            culprit: error.actor,
            first_seen: error.first_seen_at.to_s,
            last_seen: error.last_seen_at.to_s,
            count: error.event_count,
            user_count: error.approximated_user_count,
            project_id: error.project_id,
            status: error.status,
            tags: { level: nil, logger: nil },
            external_url: "http://localhost/#{project.full_path}/-/error_tracking/#{error.fingerprint}/details",
            external_base_url: "http://localhost/#{project.full_path}",
            integrated: true,
            frequency: [[1, 2], [3, 4]]
          )
        end

        context 'with missing stats' do
          let(:error) { build(:error_tracking_open_api_error, project_id: project.id, stats: nil) }

          it 'returns empty frequency' do
            is_expected.to have_attributes(
              frequency: []
            )
          end
        end

        context 'with missing frequency' do
          let(:empty_freq) { build(:error_tracking_open_api_error_stats, { frequency: nil }) }
          let(:error) { build(:error_tracking_open_api_error, project_id: project.id, stats: empty_freq) }

          it 'returns empty frequency' do
            is_expected.to have_attributes(
              frequency: []
            )
          end
        end

        context 'with missing frequency data' do
          let(:empty_freq) { build(:error_tracking_open_api_error_stats, { frequency: {} }) }
          let(:error) { build(:error_tracking_open_api_error, project_id: project.id, stats: empty_freq) }

          it 'returns empty frequency' do
            is_expected.to have_attributes(
              frequency: []
            )
          end
        end

        it 'returns no first and last release version' do
          is_expected.to have_attributes(
            first_release_version: nil,
            last_release_version: nil
          )
        end
      end

      context 'with events returned' do
        let(:first_event) { build(:error_tracking_open_api_error_event, project_id: project.id) }
        let(:first_release) { parse_json(first_event.payload).fetch('release') }
        let(:last_event) { build(:error_tracking_open_api_error_event, :golang, project_id: project.id) }
        let(:last_release) { parse_json(last_event.payload).fetch('release') }

        let(:list_events_asc) { [first_event] }
        let(:list_events_desc) { [last_event] }

        include_examples 'no logging'

        it 'returns first and last release version' do
          expect(first_release).to be_present
          expect(last_release).to be_present

          is_expected.to have_attributes(
            first_release_version: first_release,
            last_release_version: last_release
          )
        end

        def parse_json(content)
          Gitlab::Json.parse(content)
        end
      end
    end

    context 'when request fails' do
      before do
        allow_next(ErrorTrackingOpenAPI::ErrorsApi).to receive(:get_error)
          .with(project.id, error.fingerprint)
          .and_raise(api_exception)
      end

      include_examples 'exception logging'

      it { is_expected.to be_nil }
    end
  end

  describe '#list_errors' do
    let(:errors) { [] }
    let(:response_with_info) { [errors, 200, headers] }
    let(:result_errors) { result.first }
    let(:result_pagination) { result.last }

    let(:headers) do
      {
        'link' => [
          '<url?cursor=next_cursor&param>; rel="next"',
          '<url?cursor=prev_cursor&param>; rel="prev"'
        ].join(', ')
      }
    end

    subject(:result) { repository.list_errors(**params) }

    before do
      allow_next(ErrorTrackingOpenAPI::ErrorsApi).to receive(:list_errors_with_http_info)
        .with(project.id, kind_of(Hash))
        .and_return(response_with_info)
    end

    context 'with errors' do
      let(:limit) { 3 }
      let(:params) { { limit: limit } }
      let(:errors_size) { limit }
      let(:errors) { build_list(:error_tracking_open_api_error, errors_size, project_id: project.id) }

      include_examples 'no logging'

      it 'maps errors to models' do
        # All errors are identical
        error = errors.first

        expect(result_errors).to all(
          have_attributes(
            id: error.fingerprint.to_s,
            title: "#{error.name}: #{error.description}",
            message: error.description,
            culprit: error.actor,
            first_seen: error.first_seen_at,
            last_seen: error.last_seen_at,
            status: error.status,
            count: error.event_count,
            user_count: error.approximated_user_count,
            frequency: [[1, 2], [3, 4]]
          ))
      end

      context 'when n errors are returned' do
        let(:errors_size) { limit }

        include_examples 'no logging'

        it 'returns the amount of errors' do
          expect(result_errors.size).to eq(3)
        end

        it 'cursor links are preserved' do
          expect(result_pagination).to have_attributes(
            prev: 'prev_cursor',
            next: 'next_cursor'
          )
        end
      end

      context 'when less errors than requested are returned' do
        let(:errors_size) { limit - 1 }

        include_examples 'no logging'

        it 'returns the amount of errors' do
          expect(result_errors.size).to eq(2)
        end

        it 'cursor link for next is removed' do
          expect(result_pagination).to have_attributes(
            prev: 'prev_cursor',
            next: nil
          )
        end
      end
    end

    context 'with params' do
      let(:params) do
        {
          filters: { status: 'resolved', something: 'different' },
          query: 'search term',
          sort: 'first_seen',
          limit: 2,
          cursor: 'abc'
        }
      end

      include_examples 'no logging'

      it 'passes provided params to client' do
        passed_params = {
          sort: 'first_seen_desc',
          status: 'resolved',
          query: 'search term',
          cursor: 'abc',
          limit: 2
        }

        expect_next(ErrorTrackingOpenAPI::ErrorsApi).to receive(:list_errors_with_http_info)
          .with(project.id, passed_params)
          .and_return(response_with_info)

        subject
      end
    end

    context 'without explicit params' do
      let(:params) { {} }

      include_examples 'no logging'

      it 'passes default params to client' do
        passed_params = {
          sort: 'last_seen_desc',
          limit: 20,
          cursor: {}
        }

        expect_next(ErrorTrackingOpenAPI::ErrorsApi).to receive(:list_errors_with_http_info)
          .with(project.id, passed_params)
          .and_return(response_with_info)

        subject
      end
    end

    context 'when request fails' do
      let(:params) { {} }

      before do
        allow_next(ErrorTrackingOpenAPI::ErrorsApi).to receive(:list_errors_with_http_info)
          .with(project.id, kind_of(Hash))
          .and_raise(api_exception)
      end

      include_examples 'exception logging'

      specify do
        expect(result_errors).to eq([])
        expect(result_pagination).to have_attributes(
          next: nil,
          prev: nil
        )
      end
    end
  end

  describe '#last_event_for' do
    let(:params) { { sort: 'occurred_at_desc', limit: 1 } }
    let(:event) { build(:error_tracking_open_api_error_event, project_id: project.id) }
    let(:error) { build(:error_tracking_open_api_error, project_id: project.id, fingerprint: event.fingerprint) }

    subject { repository.last_event_for(error.fingerprint) }

    context 'when both event and error is returned' do
      before do
        allow_next_instance_of(ErrorTrackingOpenAPI::ErrorsApi) do |open_api|
          allow(open_api).to receive(:list_events).with(project.id, error.fingerprint, params)
            .and_return([event])

          allow(open_api).to receive(:get_error).with(project.id, error.fingerprint)
            .and_return(error)
        end
      end

      include_examples 'no logging'

      it 'returns mapped error event' do
        is_expected.to have_attributes(
          issue_id: event.fingerprint.to_s,
          date_received: error.last_seen_at,
          stack_trace_entries: kind_of(Array)
        )
      end
    end

    context 'when event is not returned' do
      before do
        allow_next(ErrorTrackingOpenAPI::ErrorsApi).to receive(:list_events)
          .with(project.id, event.fingerprint, params)
          .and_return([])
      end

      include_examples 'no logging'

      it { is_expected.to be_nil }
    end

    context 'when list_events request fails' do
      before do
        allow_next(ErrorTrackingOpenAPI::ErrorsApi).to receive(:list_events)
          .with(project.id, event.fingerprint, params)
          .and_raise(api_exception)
      end

      include_examples 'exception logging'

      it { is_expected.to be_nil }
    end

    context 'when error is not returned' do
      before do
        allow_next_instance_of(ErrorTrackingOpenAPI::ErrorsApi) do |open_api|
          allow(open_api).to receive(:list_events).with(project.id, error.fingerprint, params)
            .and_return([event])

          allow(open_api).to receive(:get_error).with(project.id, error.fingerprint)
            .and_return(nil)
        end
      end

      include_examples 'no logging'

      it { is_expected.to be_nil }
    end

    context 'when get_error request fails' do
      before do
        allow_next_instance_of(ErrorTrackingOpenAPI::ErrorsApi) do |open_api|
          allow(open_api).to receive(:list_events).with(project.id, error.fingerprint, params)
            .and_return([event])

          allow(open_api).to receive(:get_error).with(project.id, error.fingerprint)
            .and_raise(api_exception)
        end
      end

      include_examples 'exception logging'

      it { is_expected.to be_nil }
    end
  end

  describe '#update_error' do
    let(:error) { build(:error_tracking_open_api_error, project_id: project.id) }
    let(:update_params) { { status: 'resolved' } }
    let(:passed_body) { ErrorTrackingOpenAPI::ErrorUpdatePayload.new(update_params) }

    subject { repository.update_error(error.fingerprint, **update_params) }

    before do
      allow_next(ErrorTrackingOpenAPI::ErrorsApi).to receive(:update_error)
        .with(project.id, error.fingerprint, passed_body)
        .and_return(:anything)
    end

    context 'when update succeeds' do
      include_examples 'no logging'

      it { is_expected.to eq(true) }
    end

    context 'when update fails' do
      before do
        allow_next(ErrorTrackingOpenAPI::ErrorsApi).to receive(:update_error)
          .with(project.id, error.fingerprint, passed_body)
          .and_raise(api_exception)
      end

      include_examples 'exception logging'

      it { is_expected.to eq(false) }
    end
  end

  describe '#dsn_url' do
    let(:public_key) { 'abc' }
    let(:config) { ErrorTrackingOpenAPI::Configuration.default }

    subject { repository.dsn_url(public_key) }

    it do
      is_expected
        .to eq("#{config.scheme}://#{public_key}@#{config.host}/errortracking/api/v1/projects/#{project.id}")
    end
  end
end
