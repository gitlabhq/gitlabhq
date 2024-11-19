# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MergeRequests::Mergeability::CheckResult, feature_category: :code_review_workflow do
  subject(:check_result) { described_class }

  let(:time) { Time.current }

  around do |example|
    freeze_time do
      example.run
    end
  end

  describe '.default_payload' do
    it 'returns the expected defaults' do
      expect(check_result.default_payload).to eq({ last_run_at: time })
    end
  end

  describe '.success' do
    subject(:success) { check_result.success(payload: payload) }

    let(:payload) { {} }

    it 'creates a success result' do
      expect(success.status).to eq described_class::SUCCESS_STATUS
    end

    it 'uses the default payload' do
      expect(success.payload).to eq described_class.default_payload
    end

    context 'when given a payload' do
      let(:payload) { { last_run_at: time + 1.day, test: 'test' } }

      it 'uses the payload passed' do
        expect(success.payload).to eq payload
      end
    end
  end

  describe '.failed' do
    subject(:failed) { check_result.failed(payload: payload) }

    let(:payload) { {} }

    it 'creates a failure result' do
      expect(failed.status).to eq described_class::FAILED_STATUS
    end

    it 'uses the default payload' do
      expect(failed.payload).to eq described_class.default_payload
    end

    context 'when given a payload' do
      let(:payload) { { last_run_at: time + 1.day, test: 'test' } }

      it 'uses the payload passed' do
        expect(failed.payload).to eq payload
      end
    end
  end

  describe '.checking' do
    subject(:checking) { check_result.checking(payload: payload) }

    let(:payload) { {} }

    it 'creates a checking result' do
      expect(checking.status).to eq described_class::CHECKING_STATUS
    end

    it 'uses the default payload' do
      expect(checking.payload).to eq described_class.default_payload
    end

    context 'when given a payload' do
      let(:payload) { { last_run_at: time + 1.day, test: 'test' } }

      it 'uses the payload passed' do
        expect(checking.payload).to eq payload
      end
    end
  end

  describe '.inactive' do
    subject(:inactive) { check_result.inactive(payload: payload) }

    let(:payload) { {} }

    it 'creates a inactive result' do
      expect(inactive.status).to eq described_class::INACTIVE_STATUS
    end

    it 'uses the default payload' do
      expect(inactive.payload).to eq described_class.default_payload
    end

    context 'when given a payload' do
      let(:payload) { { last_run_at: time + 1.day, test: 'test' } }

      it 'uses the payload passed' do
        expect(inactive.payload).to eq payload
      end
    end
  end

  describe '.from_hash' do
    subject(:from_hash) { described_class.from_hash(hash) }

    let(:status) { described_class::SUCCESS_STATUS }
    let(:payload) { { test: 'test' } }
    let(:hash) do
      {
        status: status,
        payload: payload
      }
    end

    it 'returns the expected status and payload' do
      expect(from_hash.status).to eq status
      expect(from_hash.payload).to eq payload
    end
  end

  describe '#to_hash' do
    subject(:to_hash) { described_class.new(**hash).to_hash }

    let(:status) { described_class::SUCCESS_STATUS }
    let(:payload) { { test: 'test' } }
    let(:hash) do
      {
        status: status,
        payload: payload
      }
    end

    it 'returns the expected hash' do
      expect(to_hash).to eq hash
    end
  end

  describe '#failed?' do
    subject(:failed) { described_class.new(status: status).failed? }

    context 'when it has failed' do
      let(:status) { described_class::FAILED_STATUS }

      it 'returns true' do
        expect(failed).to eq true
      end
    end

    context 'when it has succeeded' do
      let(:status) { described_class::SUCCESS_STATUS }

      it 'returns false' do
        expect(failed).to eq false
      end
    end
  end

  describe '#success?' do
    subject(:success) { described_class.new(status: status).success? }

    context 'when it has failed' do
      let(:status) { described_class::FAILED_STATUS }

      it 'returns false' do
        expect(success).to eq false
      end
    end

    context 'when it has succeeded' do
      let(:status) { described_class::SUCCESS_STATUS }

      it 'returns true' do
        expect(success).to eq true
      end
    end
  end

  describe '#checking?' do
    subject(:checking) { described_class.new(status: status).checking? }

    context 'when it has failed' do
      let(:status) { described_class::FAILED_STATUS }

      it 'returns false' do
        expect(checking).to eq false
      end
    end

    context 'when it is checking' do
      let(:status) { described_class::CHECKING_STATUS }

      it 'returns true' do
        expect(checking).to eq true
      end
    end
  end

  describe '#unsuccessful?' do
    subject(:unsuccessful) { described_class.new(status: status).unsuccessful? }

    context 'when it has failed' do
      let(:status) { described_class::FAILED_STATUS }

      it 'returns true' do
        expect(unsuccessful).to eq true
      end
    end

    context 'when it has checking' do
      let(:status) { described_class::CHECKING_STATUS }

      it 'returns true' do
        expect(unsuccessful).to eq true
      end
    end

    context 'when it has succeeded' do
      let(:status) { described_class::SUCCESS_STATUS }

      it 'returns false' do
        expect(unsuccessful).to eq false
      end
    end
  end

  describe '#identifier' do
    let(:payload) { { identifier: 'ci_must_pass' } }

    subject(:identifier) do
      described_class
        .new(
          status: described_class::SUCCESS_STATUS,
          payload: payload
        )
        .identifier
    end

    it { is_expected.to eq(:ci_must_pass) }
  end
end
