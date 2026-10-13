# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::DeletionFailureTracking, feature_category: :groups_and_projects do
  let(:tracker_class) do
    Class.new do
      include Namespaces::DeletionFailureTracking

      public :track_destroy_failure
    end
  end

  let(:group) { build_stubbed(:group) }
  let(:error) { StandardError.new('something broke') }
  let(:attempt_count) { described_class::MAX_DESTROY_ATTEMPTS }
  let(:previous_failed_at) { (described_class::STUCK_FAILURE_WINDOW + 1.hour).ago }

  subject(:track) { tracker_class.new.track_destroy_failure(group, error, previous_failed_at, group_id: group.id) }

  before do
    allow(group).to receive(:deletion_attempt_count).and_return(attempt_count)
    allow(Gitlab::ErrorTracking).to receive(:track_exception)
  end

  def expect_no_stuck_error
    expect(Gitlab::ErrorTracking).not_to have_received(:track_exception)
      .with(an_instance_of(described_class::DeletionStuckError), anything)
  end

  it 'reports the original error with the given context, full path and attempt count' do
    track

    expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
      error,
      hash_including(group_id: group.id, full_path: group.full_path, deletion_attempt_count: attempt_count)
    )
  end

  context 'when the attempt count and the previous failure age both pass the threshold' do
    it 'also reports a DeletionStuckError' do
      track

      expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
        an_instance_of(described_class::DeletionStuckError)
          .and(having_attributes(message: 'Group stuck in deletion: something broke')),
        hash_including(
          group_id: group.id,
          deletion_attempt_count: attempt_count,
          deletion_last_failed_at: previous_failed_at
        )
      )
    end
  end

  context 'when the attempt count is below MAX_DESTROY_ATTEMPTS' do
    let(:attempt_count) { described_class::MAX_DESTROY_ATTEMPTS - 1 }

    it 'does not report a DeletionStuckError' do
      track

      expect_no_stuck_error
    end
  end

  context 'when there is no previous failure' do
    let(:previous_failed_at) { nil }

    it 'does not report a DeletionStuckError' do
      track

      expect_no_stuck_error
    end
  end

  context 'when the previous failure is inside STUCK_FAILURE_WINDOW' do
    let(:previous_failed_at) { 1.hour.ago }

    it 'does not report a DeletionStuckError' do
      track

      expect_no_stuck_error
    end
  end

  context 'when the entity was already destroyed' do
    before do
      allow(group).to receive(:destroyed?).and_return(true)
    end

    it 'reports the original error but not a DeletionStuckError' do
      track

      expect(Gitlab::ErrorTracking).to have_received(:track_exception).once.with(error, anything)
      expect_no_stuck_error
    end
  end
end
