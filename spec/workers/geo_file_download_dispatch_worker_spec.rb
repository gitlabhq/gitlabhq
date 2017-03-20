require 'spec_helper'

describe GeoFileDownloadDispatchWorker do
  before do
    @primary = create(:geo_node, :primary, host: 'primary-geo-node')
    @secondary = create(:geo_node, :current)
    allow(Gitlab::Geo).to receive(:secondary?).and_return(true)
    allow_any_instance_of(Gitlab::ExclusiveLease)
      .to receive(:try_obtain).and_return(true)
    WebMock.stub_request(:get, /primary-geo-node/).to_return(status: 200, body: "", headers: {})
  end

  subject { described_class.new }

  describe '#perform' do
    it 'does not schedule anything when node is disabled' do
      create(:lfs_object, :with_file)

      @secondary.enabled = false
      @secondary.save

      expect(GeoFileDownloadWorker).not_to receive(:perform_async)

      subject.perform
    end

    it 'executes GeoFileDownloadWorker for each LFS object' do
      create_list(:lfs_object, 2, :with_file)

      allow_any_instance_of(described_class).to receive(:over_time?).and_return(false)
      expect(GeoFileDownloadWorker).to receive(:perform_async).twice.and_call_original

      subject.perform
    end

    # Test the case where we have:
    #
    # 1. A total of 6 files in the queue, and we can load a maxmimum of 5 and send 2 at a time.
    # 2. We send 2, wait for 1 to finish, and then send again.
    it 'attempts to load a new batch without pending downloads' do
      stub_const('GeoFileDownloadDispatchWorker::DB_RETRIEVE_BATCH', 5)
      stub_const('GeoFileDownloadDispatchWorker::MAX_CONCURRENT_DOWNLOADS', 2)

      create_list(:lfs_object, 6, :with_file)

      allow_any_instance_of(described_class).to receive(:over_time?).and_return(false)

      expect(GeoFileDownloadWorker).to receive(:perform_async).exactly(6).times.and_call_original
      # For 6 downloads, we expect three database reloads:
      # 1. Load the first batch of 5.
      # 2. 4 get sent out, 1 remains. This triggers another reload, which loads in the remaining 2.
      # 3. Since the second reload filled the pipe with 2, we need to do a final reload to ensure
      #    zero are left.
      expect(subject).to receive(:load_pending_downloads).exactly(3).times.and_call_original

      Sidekiq::Testing.inline! do
        subject.perform
      end
    end
  end
end
