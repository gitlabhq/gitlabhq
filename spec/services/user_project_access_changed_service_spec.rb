# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserProjectAccessChangedService do
  describe '#execute' do
    it 'schedules the user IDs' do
      expect(AuthorizedProjectsWorker).to receive(:bulk_perform_and_wait)
        .with([[1], [2]])

      described_class.new([1, 2]).execute
    end

    it 'permits non-blocking operation' do
      expect(AuthorizedProjectsWorker).to receive(:bulk_perform_async)
        .with([[1], [2]])

      described_class.new([1, 2]).execute(blocking: false)
    end

    it 'permits low-priority operation' do
      expect(AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker).to(
        receive(:bulk_perform_in).with(
          described_class::DELAY,
          [[1], [2]],
          { batch_delay: 30.seconds, batch_size: 100 }
        )
      )

      described_class.new([1, 2]).execute(blocking: false,
                                          priority: described_class::LOW_PRIORITY)
    end
  end
end
