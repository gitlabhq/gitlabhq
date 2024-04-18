# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AlertManagement::Payload::Generic do
  let_it_be(:project) { build_stubbed(:project) }

  let(:raw_payload) { {} }

  let(:parsed_payload) { described_class.new(project: project, payload: raw_payload) }

  it_behaves_like 'subclass has expected api'

  describe '#title' do
    subject { parsed_payload.title }

    it_behaves_like 'parsable alert payload field with fallback', 'New: Alert', 'title'
  end

  describe '#severity' do
    subject { parsed_payload.severity }

    context 'when set' do
      using RSpec::Parameterized::TableSyntax

      let(:raw_payload) { { 'severity' => payload_severity } }

      where(:payload_severity, :expected_severity) do
        'critical' | :critical
        'high'     | :high
        'medium'   | :medium
        'low'      | :low
        'info'     | :info

        'CRITICAL' | :critical
        'cRiTiCaL' | :critical

        'unmapped' | nil
        1          | nil
        nil        | nil
      end

      with_them do
        it { is_expected.to eq(expected_severity) }
      end
    end

    context 'without key' do
      it { is_expected.to be_nil }
    end
  end

  describe '#monitoring_tool' do
    subject { parsed_payload.monitoring_tool }

    it_behaves_like 'parsable alert payload field', 'monitoring_tool'
  end

  describe '#service' do
    subject { parsed_payload.service }

    it_behaves_like 'parsable alert payload field', 'service'
  end

  describe '#hosts' do
    subject { parsed_payload.hosts }

    it_behaves_like 'parsable alert payload field', 'hosts'
  end

  describe '#starts_at' do
    let(:current_time) { Time.current.change(usec: 0).utc }

    subject { parsed_payload.starts_at }

    around do |example|
      travel_to(current_time) { example.run }
    end

    context 'without start_time' do
      it { is_expected.to eq(current_time) }
    end

    context "with start_time" do
      let(:value) { 10.minutes.ago.change(usec: 0).utc }

      before do
        raw_payload['start_time'] = value.to_s
      end

      it { is_expected.to eq(value) }
    end
  end

  describe '#runbook' do
    subject { parsed_payload.runbook }

    it_behaves_like 'parsable alert payload field', 'runbook'
  end

  describe '#gitlab_fingerprint' do
    let(:plain_fingerprint) { 'fingerprint' }
    let(:raw_payload) { { 'fingerprint' => plain_fingerprint } }

    subject { parsed_payload.gitlab_fingerprint }

    it 'returns a fingerprint' do
      is_expected.to eq(Digest::SHA1.hexdigest(plain_fingerprint))
    end
  end

  describe '#environment_name' do
    subject { parsed_payload.environment_name }

    it_behaves_like 'parsable alert payload field', 'gitlab_environment_name'
  end

  describe '#description' do
    subject { parsed_payload.description }

    it_behaves_like 'parsable alert payload field', 'description'
  end

  describe '#ends_at' do
    let(:current_time) { Time.current.change(usec: 0).utc }

    subject { parsed_payload.ends_at }

    around do |example|
      travel_to(current_time) { example.run }
    end

    context 'without end_time' do
      it { is_expected.to be_nil }
    end

    context "with end_time" do
      let(:value) { 10.minutes.ago.change(usec: 0).utc }

      before do
        raw_payload['end_time'] = value.to_s
      end

      it { is_expected.to eq(value) }

      context 'when integer is given' do
        let(:current_time) { Time.current }

        before do
          raw_payload['end_time'] = (current_time.to_f * 1000).to_i
        end

        it { is_expected.to be_within(1.second).of(current_time) }
      end
    end
  end

  describe '#resolved?' do
    subject { parsed_payload.resolved? }

    context 'without end time' do
      it { is_expected.to eq(false) }
    end

    context 'with end time' do
      let(:raw_payload) { { 'end_time' => Time.current.to_s } }

      it { is_expected.to eq(true) }
    end
  end

  describe '#source' do
    subject { parsed_payload.source }

    it { is_expected.to eq('Generic Alert Endpoint') }

    context 'with alerting integration provided' do
      before do
        parsed_payload.integration = instance_double('::AlertManagement::HttpIntegration', name: 'INTEGRATION')
      end

      it { is_expected.to eq('INTEGRATION') }
    end

    context 'with monitoring tool defined in the raw payload' do
      before do
        allow(parsed_payload).to receive(:monitoring_tool).and_return('TOOL')
      end

      it { is_expected.to eq('TOOL') }
    end
  end
end
