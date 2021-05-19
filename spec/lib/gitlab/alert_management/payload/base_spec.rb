# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AlertManagement::Payload::Base do
  let_it_be(:project) { create(:project) }

  let(:raw_payload) { {} }
  let(:payload_class) { described_class }

  subject(:parsed_payload) { payload_class.new(project: project, payload: raw_payload) }

  describe '.attribute' do
    subject { parsed_payload.test }

    context 'with a single path provided' do
      let(:payload_class) do
        Class.new(described_class) do
          attribute :test, paths: [['test']]
        end
      end

      it { is_expected.to be_nil }

      context 'and a matching value' do
        let(:raw_payload) { { 'test' => 'value' } }

        it { is_expected.to eq 'value' }
      end
    end

    context 'with multiple paths provided' do
      let(:payload_class) do
        Class.new(described_class) do
          attribute :test, paths: [['test'], %w(alt test)]
        end
      end

      it { is_expected.to be_nil }

      context 'and a matching value' do
        let(:raw_payload) { { 'alt' => { 'test' => 'value' } } }

        it { is_expected.to eq 'value' }
      end
    end

    context 'with a fallback provided' do
      let(:payload_class) do
        Class.new(described_class) do
          attribute :test, paths: [['test']], fallback: -> { 'fallback' }
        end
      end

      it { is_expected.to eq('fallback') }

      context 'and a matching value' do
        let(:raw_payload) { { 'test' => 'value' } }

        it { is_expected.to eq 'value' }
      end
    end

    context 'with a time type provided' do
      let(:test_time) { Time.current.change(usec: 0) }

      let(:payload_class) do
        Class.new(described_class) do
          attribute :test, paths: [['test']], type: :time
        end
      end

      it { is_expected.to be_nil }

      context 'with a compatible matching value' do
        let(:raw_payload) { { 'test' => test_time.to_s } }

        it { is_expected.to eq test_time }
      end

      context 'with a value in rfc3339 format' do
        let(:raw_payload) { { 'test' => test_time.rfc3339 } }

        it { is_expected.to eq test_time }
      end

      context 'with an incompatible matching value' do
        let(:raw_payload) { { 'test' => 'bad time' } }

        it { is_expected.to be_nil }
      end

      context 'with time in seconds' do
        let(:raw_payload) { { 'test' => 1618877936 } }

        it { is_expected.to be_nil }
      end
    end

    context 'with an integer type provided' do
      let(:payload_class) do
        Class.new(described_class) do
          attribute :test, paths: [['test']], type: :integer
        end
      end

      it { is_expected.to be_nil }

      context 'with a compatible matching value' do
        let(:raw_payload) { { 'test' => '15' } }

        it { is_expected.to eq 15 }
      end

      context 'with an incompatible matching value' do
        let(:raw_payload) { { 'test' => String } }

        it { is_expected.to be_nil }
      end

      context 'with an incompatible matching value' do
        let(:raw_payload) { { 'test' => 'apple' } }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#alert_params' do
    subject { parsed_payload.alert_params }

    context 'with every key' do
      let_it_be(:raw_payload) { { 'key' => 'value' } }
      let_it_be(:stubs) do
        {
          description: 'description',
          ends_at: Time.current,
          environment: create(:environment, project: project),
          gitlab_fingerprint: 'gitlab_fingerprint',
          hosts: 'hosts',
          monitoring_tool: 'monitoring_tool',
          gitlab_alert: create(:prometheus_alert, project: project),
          service: 'service',
          severity: 'critical',
          starts_at: Time.current,
          title: 'title'
        }
      end

      let(:expected_result) do
        {
          description: stubs[:description],
          ended_at: stubs[:ends_at],
          environment: stubs[:environment],
          fingerprint: stubs[:gitlab_fingerprint],
          hosts: [stubs[:hosts]],
          monitoring_tool: stubs[:monitoring_tool],
          payload: raw_payload,
          project_id: project.id,
          prometheus_alert: stubs[:gitlab_alert],
          service: stubs[:service],
          severity: stubs[:severity],
          started_at: stubs[:starts_at],
          title: stubs[:title]
        }
      end

      before do
        allow(parsed_payload).to receive_messages(stubs)
      end

      it { is_expected.to eq(expected_result) }

      it 'can generate a valid new alert' do
        expect(::AlertManagement::Alert.new(subject.except(:ended_at))).to be_valid
      end
    end

    context 'with too-long strings' do
      let_it_be(:stubs) do
        {
          description: 'a' * (::AlertManagement::Alert::DESCRIPTION_MAX_LENGTH + 1),
          hosts: 'b' * (::AlertManagement::Alert::HOSTS_MAX_LENGTH + 1),
          monitoring_tool: 'c' * (::AlertManagement::Alert::TOOL_MAX_LENGTH + 1),
          service: 'd' * (::AlertManagement::Alert::SERVICE_MAX_LENGTH + 1),
          title: 'e' * (::AlertManagement::Alert::TITLE_MAX_LENGTH + 1)
        }
      end

      before do
        allow(parsed_payload).to receive_messages(stubs)
      end

      it do
        is_expected.to eq({
          description: stubs[:description].truncate(AlertManagement::Alert::DESCRIPTION_MAX_LENGTH),
          hosts: ['b' * ::AlertManagement::Alert::HOSTS_MAX_LENGTH],
          monitoring_tool: stubs[:monitoring_tool].truncate(::AlertManagement::Alert::TOOL_MAX_LENGTH),
          service: stubs[:service].truncate(::AlertManagement::Alert::SERVICE_MAX_LENGTH),
          project_id: project.id,
          title: stubs[:title].truncate(::AlertManagement::Alert::TITLE_MAX_LENGTH)
        })
      end
    end

    context 'with too-long hosts array' do
      let(:hosts) { %w(abc def ghij) }
      let(:shortened_hosts) { %w(abc def ghi) }

      before do
        stub_const('::AlertManagement::Alert::HOSTS_MAX_LENGTH', 9)
        allow(parsed_payload).to receive(:hosts).and_return(hosts)
      end

      it { is_expected.to eq(hosts: shortened_hosts, project_id: project.id) }

      context 'with host cut off between elements' do
        let(:hosts) { %w(abcde fghij) }
        let(:shortened_hosts) { %w(abcde fghi) }

        it { is_expected.to eq({ hosts: shortened_hosts, project_id: project.id }) }
      end

      context 'with nested hosts' do
        let(:hosts) { ['abc', ['de', 'f'], 'g', 'hij'] } # rubocop:disable Style/WordArray
        let(:shortened_hosts) { %w(abc de f g hi) }

        it { is_expected.to eq({ hosts: shortened_hosts, project_id: project.id }) }
      end
    end
  end

  describe '#gitlab_fingerprint' do
    subject { parsed_payload.gitlab_fingerprint }

    it { is_expected.to be_nil }

    context 'when plain_gitlab_fingerprint is defined' do
      before do
        allow(parsed_payload)
          .to receive(:plain_gitlab_fingerprint)
          .and_return('fingerprint')
      end

      it 'returns a fingerprint' do
        is_expected.to eq(Digest::SHA1.hexdigest('fingerprint'))
      end
    end
  end

  describe '#environment' do
    let_it_be(:environment) { create(:environment, project: project, name: 'production') }

    subject { parsed_payload.environment }

    before do
      allow(parsed_payload).to receive(:environment_name).and_return(environment_name)
    end

    context 'without an environment name' do
      let(:environment_name) { nil }

      it { is_expected.to be_nil }
    end

    context 'with a non-matching environment name' do
      let(:environment_name) { 'other_environment' }

      it { is_expected.to be_nil }
    end

    context 'with a matching environment name' do
      let(:environment_name) { 'production' }

      it { is_expected.to eq(environment) }
    end
  end

  describe '#resolved?' do
    before do
      allow(parsed_payload).to receive(:status).and_return(status)
    end

    subject { parsed_payload.resolved? }

    context 'when status is not defined' do
      let(:status) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when status is not resovled' do
      let(:status) { 'firing' }

      it { is_expected.to be_falsey }
    end

    context 'when status is resovled' do
      let(:status) { 'resolved' }

      it { is_expected.to be_truthy }
    end
  end

  describe '#has_required_attributes?' do
    subject { parsed_payload.has_required_attributes? }

    it { is_expected.to be(true) }
  end
end
