# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateElasticsearchNumberOfShardsInApplicationSettingsForGitlabCom, feature_category: :global_search do
  let(:settings) { table(:application_settings) }

  describe "#up" do
    it 'does nothing when not in gitlab.com' do
      record = settings.create!

      expect { migrate! }.not_to change { record.reload.elasticsearch_worker_number_of_shards }
    end

    it 'updates elasticsearch_worker_number_of_shards when gitlab.com' do
      allow(Gitlab).to receive(:com?).and_return(true)

      record = settings.create!

      expect { migrate! }.to change { record.reload.elasticsearch_worker_number_of_shards }.from(2).to(16)
    end
  end

  describe "#down" do
    it 'does nothing when not in gitlab.com' do
      record = settings.create!(elasticsearch_worker_number_of_shards: 16)

      migrate!

      expect { schema_migrate_down! }.not_to change { record.reload.elasticsearch_worker_number_of_shards }
    end

    it 'updates elasticsearch_worker_number_of_shards when gitlab.com' do
      allow(Gitlab).to receive(:com?).and_return(true)

      record = settings.create!(elasticsearch_worker_number_of_shards: 16)

      migrate!

      expect { schema_migrate_down! }.to change { record.reload.elasticsearch_worker_number_of_shards }.from(16).to(2)
    end
  end
end
