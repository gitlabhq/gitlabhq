# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::RunnerReleases, feature_category: :fleet_visibility do
  subject { described_class.instance }

  let(:runner_releases_url) { 'http://testurl.com/runner_public_releases' }

  def releases
    subject.releases
  end

  def releases_by_minor
    subject.releases_by_minor
  end

  before do
    subject.reset_backoff!

    allow(subject).to receive(:runner_releases_url).and_return(runner_releases_url)
  end

  describe 'caching behavior', :use_clean_rails_memory_store_caching do
    before do
      allow(Gitlab::HTTP).to receive(:get).with(runner_releases_url, anything).once { mock_http_response(response) }
    end

    shared_examples 'requests that follow cache status' do |validity_period|
      context "almost #{validity_period.inspect} later" do
        let(:followup_request_interval) { validity_period - 0.001.seconds }

        it 'returns cached releases' do
          releases

          travel followup_request_interval do
            expect(Gitlab::HTTP).not_to receive(:get)

            if expected_releases
              expected_result_by_minor = expected_releases.group_by(&:without_patch).transform_values(&:max)
            end

            expect(releases).to eq(expected_releases)
            expect(releases_by_minor).to eq(expected_result_by_minor)
          end
        end
      end

      context "after #{validity_period.inspect}" do
        let(:followup_request_interval) { validity_period + 1.second }
        let(:followup_response) { (response || []) + [{ 'name' => 'v14.9.2' }] }

        it 'checks new releases' do
          releases

          travel followup_request_interval do
            expect(Gitlab::HTTP).to receive(:get)
              .with(runner_releases_url, anything)
              .once { mock_http_response(followup_response) }

            new_releases = (expected_releases || []) + [Gitlab::VersionInfo.new(14, 9, 2)]
            new_releases_by_minor_version = (expected_releases_by_minor || {}).merge(
              Gitlab::VersionInfo.new(14, 9, 0) => Gitlab::VersionInfo.new(14, 9, 2)
            )
            expect(releases).to eq(new_releases)
            expect(releases_by_minor).to eq(new_releases_by_minor_version)
          end
        end
      end
    end

    shared_examples 'a service implementing exponential backoff' do |opts|
      it 'performs exponential backoff on requests', :aggregate_failures do
        start_time = Time.now.utc.change(usec: 0)

        http_call_timestamp_offsets = []
        allow(Gitlab::HTTP).to receive(:get).with(runner_releases_url, anything) do
          http_call_timestamp_offsets << (Time.now.utc - start_time)

          err_class = opts&.dig(:raise_error)
          raise err_class if err_class

          mock_http_response(response)
        end

        # An initial HTTP request fails
        travel_to(start_time)
        subject.reset_backoff!
        expect(releases).to be_nil
        expect(releases_by_minor).to be_nil

        # Successive failed requests result in HTTP requests only after specific backoff periods
        backoff_periods = [5, 10, 20, 40, 80, 160, 320, 640, 1280, 2560, 3600].map(&:seconds)
        backoff_periods.each do |period|
          travel(period - 1.second)
          expect(releases).to be_nil
          expect(releases_by_minor).to be_nil

          travel 1.second
          expect(releases).to be_nil
          expect(releases_by_minor).to be_nil
        end

        expect(http_call_timestamp_offsets).to eq([0, 5, 15, 35, 75, 155, 315, 635, 1275, 2555, 5115, 8715])

        # Finally a successful HTTP request results in releases being returned
        allow(Gitlab::HTTP).to receive(:get)
          .with(runner_releases_url, anything)
          .once { mock_http_response([{ 'name' => 'v14.9.1-beta1-ee' }]) }
        travel 1.hour
        expect(releases).not_to be_nil
        expect(releases_by_minor).not_to be_nil
      end
    end

    context 'when request results in timeout' do
      let(:response) {}
      let(:expected_releases) { nil }
      let(:expected_releases_by_minor) { nil }

      it_behaves_like 'requests that follow cache status', 5.seconds
      it_behaves_like 'a service implementing exponential backoff', raise_error: Net::OpenTimeout
      it_behaves_like 'a service implementing exponential backoff', raise_error: Errno::ETIMEDOUT
    end

    context 'when response is nil' do
      let(:response) { nil }
      let(:expected_releases) { nil }
      let(:expected_releases_by_minor) { nil }

      it_behaves_like 'requests that follow cache status', 5.seconds
      it_behaves_like 'a service implementing exponential backoff'
    end

    context 'when response is not nil' do
      let(:response) { [{ 'name' => 'v14.9.1-beta1-ee' }, { 'name' => 'v14.9.0' }] }
      let(:expected_releases) do
        [
          Gitlab::VersionInfo.new(14, 9, 0),
          Gitlab::VersionInfo.new(14, 9, 1, '-beta1-ee')
        ]
      end

      let(:expected_releases_by_minor) do
        {
          Gitlab::VersionInfo.new(14, 9, 0) => Gitlab::VersionInfo.new(14, 9, 1, '-beta1-ee')
        }
      end

      it_behaves_like 'requests that follow cache status', 1.day
    end
  end

  describe '#releases', :use_clean_rails_memory_store_caching do
    before do
      allow(Gitlab::HTTP).to receive(:get).with(runner_releases_url, anything).once { mock_http_response(response) }
    end

    context 'when response is nil' do
      let(:response) { nil }
      let(:expected_result) { nil }

      it 'returns nil' do
        expect(releases).to be_nil
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

      context 'when fetching runner releases is disabled' do
        before do
          stub_application_setting(update_runner_versions_enabled: false)
        end

        it 'returns nil' do
          expect(releases).to be_nil
        end
      end
    end

    context 'when response contains unexpected input type' do
      let(:response) { 'error' }

      it { expect(releases).to be_nil }
    end

    context 'when response contains unexpected input array' do
      let(:response) { ['error'] }

      it { expect(releases).to be_nil }
    end
  end

  describe '#releases_by_minor', :use_clean_rails_memory_store_caching do
    before do
      allow(Gitlab::HTTP).to receive(:get).with(runner_releases_url, anything).once { mock_http_response(response) }
    end

    context 'when response is nil' do
      let(:response) { nil }
      let(:expected_result) { nil }

      it 'returns nil' do
        expect(releases_by_minor).to be_nil
      end
    end

    context 'when response is not nil' do
      let(:response) { [{ 'name' => 'v14.9.1-beta1-ee' }, { 'name' => 'v14.9.0' }, { 'name' => 'v14.8.1' }] }
      let(:expected_result) do
        {
          Gitlab::VersionInfo.new(14, 8, 0) => Gitlab::VersionInfo.new(14, 8, 1),
          Gitlab::VersionInfo.new(14, 9, 0) => Gitlab::VersionInfo.new(14, 9, 1, '-beta1-ee')
        }
      end

      it 'returns parsed and grouped Gitlab::VersionInfo objects' do
        expect(releases_by_minor).to eq(expected_result)
      end

      context 'when fetching runner releases is disabled' do
        before do
          stub_application_setting(update_runner_versions_enabled: false)
        end

        it 'returns nil' do
          expect(releases_by_minor).to be_nil
        end
      end
    end

    context 'when response contains unexpected input type' do
      let(:response) { 'error' }

      it { expect(releases_by_minor).to be_nil }
    end

    context 'when response contains unexpected input array' do
      let(:response) { ['error'] }

      it { expect(releases_by_minor).to be_nil }
    end
  end

  describe '#enabled?' do
    it { is_expected.to be_enabled }

    context 'when fetching runner releases is disabled' do
      before do
        stub_application_setting(update_runner_versions_enabled: false)
      end

      it { is_expected.not_to be_enabled }
    end
  end

  def mock_http_response(response)
    http_response = instance_double(HTTParty::Response)

    allow(http_response).to receive(:success?).and_return(!response.nil?)
    allow(http_response).to receive(:parsed_response).and_return(response)

    http_response
  end
end
