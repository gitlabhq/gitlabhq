# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::RunnerReleases do
  subject { described_class.instance }

  describe '#releases' do
    before do
      subject.reset!

      stub_application_setting(public_runner_releases_url: 'the release API URL')
      allow(Gitlab::HTTP).to receive(:try_get).with('the release API URL').once { mock_http_response(response) }
    end

    def releases
      subject.releases
    end

    shared_examples 'requests that follow cache status' do |validity_period|
      context "almost #{validity_period.inspect} later" do
        let(:followup_request_interval) { validity_period - 0.001.seconds }

        it 'returns cached releases' do
          releases

          travel followup_request_interval do
            expect(Gitlab::HTTP).not_to receive(:try_get)

            expect(releases).to eq(expected_result)
          end
        end
      end

      context "after #{validity_period.inspect}" do
        let(:followup_request_interval) { validity_period + 1.second }
        let(:followup_response) { (response || []) + [{ 'name' => 'v14.9.2' }] }

        it 'checks new releases' do
          releases

          travel followup_request_interval do
            expect(Gitlab::HTTP).to receive(:try_get).with('the release API URL').once { mock_http_response(followup_response) }

            expect(releases).to eq((expected_result || []) + [Gitlab::VersionInfo.new(14, 9, 2)])
          end
        end
      end
    end

    context 'when response is nil' do
      let(:response) { nil }
      let(:expected_result) { nil }

      it 'returns nil' do
        expect(releases).to be_nil
      end

      it_behaves_like 'requests that follow cache status', 5.seconds

      it 'performs exponential backoff on requests', :aggregate_failures do
        start_time = Time.now.utc.change(usec: 0)

        http_call_timestamp_offsets = []
        allow(Gitlab::HTTP).to receive(:try_get).with('the release API URL') do
          http_call_timestamp_offsets << Time.now.utc - start_time
          mock_http_response(response)
        end

        # An initial HTTP request fails
        travel_to(start_time)
        subject.reset!
        expect(releases).to be_nil

        # Successive failed requests result in HTTP requests only after specific backoff periods
        backoff_periods = [5, 10, 20, 40, 80, 160, 320, 640, 1280, 2560, 3600].map(&:seconds)
        backoff_periods.each do |period|
          travel(period - 1.second)
          expect(releases).to be_nil

          travel 1.second
          expect(releases).to be_nil
        end

        expect(http_call_timestamp_offsets).to eq([0, 5, 15, 35, 75, 155, 315, 635, 1275, 2555, 5115, 8715])

        # Finally a successful HTTP request results in releases being returned
        allow(Gitlab::HTTP).to receive(:try_get)
          .with('the release API URL')
          .once { mock_http_response([{ 'name' => 'v14.9.1-beta1-ee' }]) }
        travel 1.hour
        expect(releases).not_to be_nil
      end
    end

    context 'when response is not nil' do
      let(:response) { [{ 'name' => 'v14.9.1-beta1-ee' }, { 'name' => 'v14.9.0' }] }
      let(:expected_result) do
        [
          Gitlab::VersionInfo.new(14, 9, 0),
          Gitlab::VersionInfo.new(14, 9, 1, '-beta1-ee')
        ]
      end

      it 'returns parsed and sorted Gitlab::VersionInfo objects' do
        expect(releases).to eq(expected_result)
      end

      it_behaves_like 'requests that follow cache status', 1.day
    end

    def mock_http_response(response)
      http_response = instance_double(HTTParty::Response)

      allow(http_response).to receive(:success?).and_return(response.present?)
      allow(http_response).to receive(:parsed_response).and_return(response)

      http_response
    end
  end
end
