# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MigrateExternalDiffsService, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let(:diff) { merge_request.merge_request_diff }

  describe '.enqueue!' do
    around do |example|
      Sidekiq::Testing.fake! { example.run }
    end

    it 'enqueues nothing if external diffs are disabled' do
      expect(diff).not_to be_stored_externally

      expect { described_class.enqueue! }
        .not_to change { MigrateExternalDiffsWorker.jobs.count }
    end

    it 'enqueues eligible in-database diffs if external diffs are enabled' do
      expect(diff).not_to be_stored_externally

      stub_external_diffs_setting(enabled: true)

      expect { described_class.enqueue! }
        .to change { MigrateExternalDiffsWorker.jobs.count }
        .by(1)
    end
  end

  describe '#execute' do
    it 'migrates an in-database diff to the external store' do
      expect(diff).not_to be_stored_externally

      stub_external_diffs_setting(enabled: true)

      described_class.new(diff).execute

      expect(diff).to be_stored_externally
    end
  end
end
