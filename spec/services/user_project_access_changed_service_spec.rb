require 'spec_helper'

describe UserProjectAccessChangedService do
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
  end
end
