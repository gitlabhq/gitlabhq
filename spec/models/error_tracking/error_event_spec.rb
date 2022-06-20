# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::ErrorEvent do
  include AfterNextHelpers

  let_it_be(:event) { create(:error_tracking_error_event) }

  describe 'relationships' do
    it { is_expected.to belong_to(:error) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
    it { is_expected.to validate_presence_of(:occurred_at) }
    it { is_expected.to validate_length_of(:level).is_at_most(255) }
    it { is_expected.to validate_length_of(:environment).is_at_most(255) }
  end

  describe '#stacktrace' do
    it 'builds a stacktrace' do
      expect_next(ErrorTracking::StacktraceBuilder, event.payload)
        .to receive(:stacktrace).and_call_original

      expect(event.stacktrace).to be_kind_of(Array)
      expect(event.stacktrace).not_to be_empty
    end
  end

  describe '#to_sentry_error_event' do
    it { expect(event.to_sentry_error_event).to be_kind_of(Gitlab::ErrorTracking::ErrorEvent) }
  end
end
