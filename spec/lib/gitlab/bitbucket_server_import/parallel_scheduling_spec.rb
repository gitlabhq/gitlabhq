# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::ParallelScheduling, feature_category: :importers do
  let_it_be(:project) { build(:project) }

  describe '#calculate_job_delay' do
    let(:importer_class) do
      Class.new do
        include Gitlab::BitbucketServerImport::ParallelScheduling

        def collection_method
          :issues
        end
      end
    end

    let(:importer) { importer_class.new(project) }

    before do
      stub_application_setting(concurrent_bitbucket_server_import_jobs_limit: 2)
    end

    it 'returns an incremental delay', :freeze_time do
      expect(importer.send(:calculate_job_delay, 1)).to eq(0.5.minutes + 1.second)
      expect(importer.send(:calculate_job_delay, 100)).to eq(50.minutes + 1.second)
    end

    it 'deducts the runtime from the delay', :freeze_time do
      allow(importer).to receive(:job_started_at).and_return(1.second.ago)

      expect(importer.send(:calculate_job_delay, 1)).to eq(0.5.minutes)
      expect(importer.send(:calculate_job_delay, 100)).to eq(50.minutes)
    end
  end
end
