# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AlertManagement::Payload::Base do
  let_it_be(:project) { build_stubbed(:project) }
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
    let(:payload_class) do
      Class.new(described_class) do
        def title
          'title'
        end

        def description
          'description'
        end
      end
    end

    subject { parsed_payload.alert_params }

    it { is_expected.to eq({ description: 'description', project_id: project.id, title: 'title' }) }
  end

  describe '#gitlab_fingerprint' do
    subject { parsed_payload.gitlab_fingerprint }

    it { is_expected.to be_nil }

    context 'when plain_gitlab_fingerprint is defined' do
      let(:payload_class) do
        Class.new(described_class) do
          def plain_gitlab_fingerprint
            'fingerprint'
          end
        end
      end

      it 'returns a fingerprint' do
        is_expected.to eq(Digest::SHA1.hexdigest('fingerprint'))
      end
    end
  end
end
