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
    end
  end
end
