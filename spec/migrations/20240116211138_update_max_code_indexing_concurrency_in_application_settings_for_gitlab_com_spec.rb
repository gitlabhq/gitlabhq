# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateMaxCodeIndexingConcurrencyInApplicationSettingsForGitlabCom, feature_category: :global_search do
  let(:settings) { table(:application_settings) }

  describe "#up" do
    subject(:up) { migrate! }

    it 'does nothing when not in gitlab.com' do
      record = settings.create!

      expect { up }.not_to change { record.reload.elasticsearch_max_code_indexing_concurrency }
    end

    it 'updates elasticsearch_worker_number_of_shards when gitlab.com' do
      allow(Gitlab).to receive(:com?).and_return(true)

      record = settings.create!

      expect { up }.to change { record.reload.elasticsearch_max_code_indexing_concurrency }.from(30).to(60)
    end
  end

  describe "#down" do
    subject(:down) { schema_migrate_down! }

    it 'does nothing when not in gitlab.com' do
      record = settings.create!(elasticsearch_max_code_indexing_concurrency: 60)

      migrate!

      expect { down }.not_to change { record.reload.elasticsearch_max_code_indexing_concurrency }
    end

    it 'updates elasticsearch_worker_number_of_shards when gitlab.com' do
      allow(Gitlab).to receive(:com?).and_return(true)

      record = settings.create!(elasticsearch_max_code_indexing_concurrency: 60)

      migrate!

      expect { down }.to change { record.reload.elasticsearch_max_code_indexing_concurrency }.from(60).to(30)
    end
  end
end
