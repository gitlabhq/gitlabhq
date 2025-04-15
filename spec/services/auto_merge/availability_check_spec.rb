# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoMerge::AvailabilityCheck, feature_category: :shared do
  context 'with invalid status' do
    it { expect { described_class.new(status: :invalid) }.to raise_error(ArgumentError, 'Invalid status') }
  end

  describe '.success' do
    it 'creates a success response without an unavailable_reason or unsuccessful_check' do
      expect(described_class.success).to be_truthy
    end
  end

  describe '.error' do
    it 'creates an error response with an unavailable reason' do
      response = described_class.error(unavailable_reason: :forbidden)

      expect(response).to be_truthy
      expect(response.unavailable_reason).to eq(:forbidden)
    end

    it 'creates an error response with unsuccessful_check' do
      response = described_class.error(unavailable_reason: :forbidden, unsuccessful_check: 'failed')

      expect(response).to be_truthy
      expect(response.unavailable_reason).to eq(:forbidden)
      expect(response.unsuccessful_check).to eq('failed')
    end

    context 'without an unavailable reason' do
      it 'returns the default error' do
        response = described_class.error

        expect(response.unavailable_reason).to eq(:default)
      end
    end
  end

  describe '#available' do
    it 'returns true for an available response' do
      expect(described_class.success.available?).to be(true)
    end

    it 'returns false when unavailable' do
      expect(described_class.error(unavailable_reason: :forbidden)
      .available?).to be(false)
    end
  end

  describe '#abort_message' do
    AutoMerge::AvailabilityCheck::ABORT_REASONS.each_key do |reason|
      next if reason == :mergeability_checks_failed

      it "returns the correct message for reason: #{reason}" do
        check = described_class.error(unavailable_reason: reason, unsuccessful_check: 'failed')
        expect(check.abort_message).to eq(AutoMerge::AvailabilityCheck::ABORT_REASONS[reason])
      end
    end

    it 'falls back to the default message if reason is unknown' do
      check = described_class.error(unavailable_reason: :not_real)
      expect(check.abort_message).to eq(AutoMerge::AvailabilityCheck::ABORT_REASONS[:default])
    end

    context 'when mergeability_checks_failed' do
      it 'renders unknown check if unsuccessful_check is nil' do
        check = described_class.error(unavailable_reason: :mergeability_checks_failed)
        expect(check.abort_message).to eq(
          AutoMerge::AvailabilityCheck::ABORT_REASONS[:mergeability_checks_failed].call(nil)
        )
      end

      it 'interpolates the unsuccessful_check value in the message' do
        failed_check = :failed_check
        check = described_class.error(unavailable_reason: :mergeability_checks_failed, unsuccessful_check: failed_check)
        expect(check.abort_message).to eq(
          AutoMerge::AvailabilityCheck::ABORT_REASONS[:mergeability_checks_failed].call(failed_check)
        )
      end
    end
  end
end
