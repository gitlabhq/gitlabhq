# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AlertManagement::Payload::Prometheus do
  let_it_be(:project) { create(:project) }

  let(:raw_payload) { {} }

  let(:parsed_payload) { described_class.new(project: project, payload: raw_payload) }

  it_behaves_like 'subclass has expected api'

  shared_context 'with environment' do
    let_it_be(:environment) { create(:environment, project: project, name: 'production') }
  end

  describe '#title' do
    subject { parsed_payload.title }

    it_behaves_like 'parsable alert payload field',
                    'annotations/title',
                    'annotations/summary',
                    'labels/alertname'
  end

  describe '#description' do
    subject { parsed_payload.description }

    it_behaves_like 'parsable alert payload field', 'annotations/description'
  end

  describe '#annotations' do
    subject { parsed_payload.annotations }

    it_behaves_like 'parsable alert payload field', 'annotations'
  end

  describe '#status' do
    subject { parsed_payload.status }

    it_behaves_like 'parsable alert payload field', 'status'
  end

  describe '#starts_at' do
    let(:current_time) { Time.current.utc }

    around do |example|
      freeze_time { example.run }
    end

    subject { parsed_payload.starts_at }

    context 'without payload' do
      it { is_expected.to eq(current_time) }
    end

    context "with startsAt" do
      let(:value) { 10.minutes.ago.change(usec: 0).utc }
      let(:raw_payload) { { 'startsAt' => value.rfc3339 } }

      it { is_expected.to eq(value) }
    end
  end

  describe '#ends_at' do
    subject { parsed_payload.ends_at }

    context 'without payload' do
      it { is_expected.to be_nil }
    end

    context "with endsAt" do
      let(:value) { Time.current.change(usec: 0).utc }
      let(:raw_payload) { { 'endsAt' => value.rfc3339 } }

      it { is_expected.to eq(value) }
    end
  end

  describe '#generator_url' do
    subject { parsed_payload.generator_url }

    it_behaves_like 'parsable alert payload field', 'generatorURL'
  end

  describe '#runbook' do
    subject { parsed_payload.runbook }

    it_behaves_like 'parsable alert payload field', 'annotations/runbook'
  end

  describe '#alert_markdown' do
    subject { parsed_payload.alert_markdown }

    it_behaves_like 'parsable alert payload field', 'annotations/gitlab_incident_markdown'
  end

  describe '#environment_name' do
    subject { parsed_payload.environment_name }

    it_behaves_like 'parsable alert payload field', 'labels/gitlab_environment_name'
  end

  describe '#gitlab_y_label' do
    subject { parsed_payload.gitlab_y_label }

    it_behaves_like 'parsable alert payload field',
                    'annotations/gitlab_y_label',
                    'annotations/title',
                    'annotations/summary',
                    'labels/alertname'
  end

  describe '#monitoring_tool' do
    subject { parsed_payload.monitoring_tool }

    it { is_expected.to eq('Prometheus') }
  end

  describe '#full_query' do
    using RSpec::Parameterized::TableSyntax

    subject { parsed_payload.full_query }

    where(:generator_url, :expected_query) do
      nil | nil
      'http://localhost' | nil
      'invalid url' | nil
      'http://localhost:9090/graph?g1.expr=vector%281%29' | nil
      'http://localhost:9090/graph?g0.expr=vector%281%29' | 'vector(1)'
    end

    with_them do
      let(:raw_payload) { { 'generatorURL' => generator_url } }

      it { is_expected.to eq(expected_query) }
    end
  end

  describe '#environment' do
    subject { parsed_payload.environment }

    it { is_expected.to be_nil }

    context 'with environment_name' do
      let(:raw_payload) { { 'labels' => { 'gitlab_environment_name' => 'production' } } }

      it { is_expected.to be_nil }

      context 'with matching environment' do
        include_context 'with environment'

        it { is_expected.to eq(environment) }
      end
    end
  end

  describe '#gitlab_fingerprint' do
    let(:raw_payload) do
      {
        'startsAt' => Time.current.to_s,
        'generatorURL' => 'http://localhost:9090/graph?g0.expr=vector%281%29',
        'annotations' => { 'title' => 'title' }
      }
    end

    subject { parsed_payload.gitlab_fingerprint }

    it 'returns a fingerprint' do
      plain_fingerprint = [
        parsed_payload.send(:starts_at_raw),
        parsed_payload.title,
        parsed_payload.full_query
      ].join('/')

      is_expected.to eq(Digest::SHA1.hexdigest(plain_fingerprint))
    end
  end

  describe '#metrics_dashboard_url' do
    include_context 'self-managed prometheus alert attributes' do
      let(:raw_payload) { payload }
    end

    subject { parsed_payload.metrics_dashboard_url }

    it { is_expected.to eq(dashboard_url_for_alert) }

    context 'without environment' do
      let(:raw_payload) { payload.except('labels') }

      it { is_expected.to be_nil }
    end

    context 'without full query' do
      let(:raw_payload) { payload.except('generatorURL') }

      it { is_expected.to be_nil }
    end

    context 'without title' do
      let(:raw_payload) { payload.except('annotations') }

      it { is_expected.to be_nil }
    end
  end

  describe '#has_required_attributes?' do
    let(:starts_at) { Time.current.change(usec: 0).utc }
    let(:raw_payload) { { 'annotations' => { 'title' => 'title' }, 'startsAt' => starts_at.rfc3339 } }

    subject { parsed_payload.has_required_attributes? }

    it { is_expected.to be_truthy }

    context 'without project' do
      let(:parsed_payload) { described_class.new(project: nil, payload: raw_payload) }

      it { is_expected.to be_falsey }
    end

    context 'without title' do
      let(:raw_payload) { { 'startsAt' => starts_at.rfc3339 } }

      it { is_expected.to be_falsey }
    end

    context 'without startsAt' do
      let(:raw_payload) { { 'annotations' => { 'title' => 'title' } } }

      it { is_expected.to be_falsey }
    end

    context 'without payload' do
      let(:parsed_payload) { described_class.new(project: project, payload: nil) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#severity' do
    subject { parsed_payload.severity }

    context 'when set' do
      using RSpec::Parameterized::TableSyntax

      let(:raw_payload) { { 'labels' => { 'severity' => payload_severity } } }

      where(:payload_severity, :expected_severity) do
        'critical' | :critical
        'high'     | :high
        'medium'   | :medium
        'low'      | :low
        'info'     | :info

        's1'       | :critical
        's2'       | :high
        's3'       | :medium
        's4'       | :low
        's5'       | :info
        'p1'       | :critical
        'p2'       | :high
        'p3'       | :medium
        'p4'       | :low
        'p5'       | :info

        'CRITICAL' | :critical
        'cRiTiCaL' | :critical
        'S1'       | :critical

        'unmapped' | nil
        1          | nil
        nil        | nil

        'debug'       | :info
        'information' | :info
        'notice'      | :info
        'warn'        | :low
        'warning'     | :low
        'minor'       | :low
        'error'       | :medium
        'major'       | :high
        'emergency'   | :critical
        'fatal'       | :critical

        'alert'       | :medium
        'page'        | :high
      end

      with_them do
        it { is_expected.to eq(expected_severity) }
      end
    end

    context 'without key' do
      it { is_expected.to be_nil }
    end
  end
end
