require 'spec_helper'

describe Gitlab::Geo, lib: true do
  let(:primary_node) { FactoryGirl.create(:geo_node, :primary) }
  let(:secondary_node) { FactoryGirl.create(:geo_node) }

  describe 'current_node' do
    before(:each) { primary_node }

    it 'returns a GeoNode instance' do
      expect(described_class.current_node).to eq(primary_node)
    end
  end

  describe 'primary_node' do
    before(:each) do
      primary_node
      secondary_node
    end

    it 'returns a GeoNode primary instance' do
      expect(described_class.current_node).to eq(primary_node)
    end
  end

  describe 'enabled?' do
    context 'when any GeoNode exists' do
      before(:each) { secondary_node }

      it 'returns true' do
        expect(described_class.enabled?).to be_truthy
      end
    end

    context 'when no GeoNode exists' do
      it 'returns false' do
        expect(described_class.enabled?).to be_falsey
      end
    end

    context 'with RequestStore enabled' do
      before do
        RequestStore.begin!
      end

      after do
        RequestStore.end!
        RequestStore.clear!
      end

      it 'return false when no GeoNode exists' do
        expect(GeoNode).to receive(:exists?).once.and_call_original

        2.times { expect(described_class.enabled?).to be_falsey }
      end
    end
  end

  describe 'readonly?' do
    context 'when current node is secondary' do
      before(:each) { secondary_node }

      it 'returns true' do
        allow(described_class).to receive(:current_node) { secondary_node }
        expect(described_class.secondary?).to be_truthy
      end
    end

    context 'current node is primary' do
      before(:each) { primary_node }

      it 'returns false when ' do
        allow(described_class).to receive(:current_node) { primary_node }
        expect(described_class.secondary?).to be_falsey
      end
    end
  end

  describe 'geo_node?' do
    it 'returns true if a node with specific host and port exists' do
      expect(described_class.geo_node?(host: primary_node.host, port: primary_node.port)).to be_truthy
    end

    it 'returns false if specified host and port doesnt match any existing node' do
      expect(described_class.geo_node?(host: 'inexistent', port: 1234)).to be_falsey
    end
  end

  describe 'license_allows?' do
    it 'returns true if license has Geo addon' do
      allow_any_instance_of(License).to receive(:add_on?).with('GitLab_Geo') { true }
      expect(described_class.license_allows?).to be_truthy
    end

    it 'returns false if license doesnt have Geo addon' do
      allow_any_instance_of(License).to receive(:add_on?).with('GitLab_Geo') { false }
      expect(described_class.license_allows?).to be_falsey
    end

    it 'returns false if no license is present' do
      allow(License).to receive(:current) { nil }
      expect(described_class.license_allows?).to be_falsey
    end
  end

  describe '.generate_access_keys' do
    it 'returns a public and secret access key' do
      keys = described_class.generate_access_keys

      expect(keys[:access_key].length).to eq(20)
      expect(keys[:secret_access_key].length).to eq(40)
    end
  end

  describe '.configure_cron_jobs!' do
    def init_cron_job(job_name, class_name)
      Sidekiq::Cron::Job.create(
        name: job_name,
        cron: '0 * * * *',
        class: class_name
      )
    end

    before(:all) do
      jobs = %w(geo_bulk_notify_worker geo_repository_sync_worker)

      jobs.each { |job| init_cron_job(job, job.camelize) }
      # TODO: Make this name consistent
      init_cron_job('geo_download_dispatch_worker', 'GeoFileDownloadDispatchWorker')
    end

    it 'activates cron jobs for primary' do
      allow(described_class).to receive(:primary?).and_return(true)
      described_class.configure_cron_jobs!

      expect(described_class.bulk_notify_job).to be_enabled
      expect(described_class.repository_sync_job).not_to be_enabled
      expect(described_class.file_download_job).not_to be_enabled
    end

    it 'activates cron jobs for secondary' do
      allow(described_class).to receive(:secondary?).and_return(true)
      described_class.configure_cron_jobs!

      expect(described_class.bulk_notify_job).not_to be_enabled
      expect(described_class.repository_sync_job).to be_enabled
      expect(described_class.file_download_job).to be_enabled
    end

    it 'deactivates all jobs when Geo is not active' do
      described_class.configure_cron_jobs!

      expect(described_class.bulk_notify_job).not_to be_enabled
      expect(described_class.repository_sync_job).not_to be_enabled
      expect(described_class.file_download_job).not_to be_enabled
    end
  end
end
