# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateRequeueWorkersInApplicationSettingsForGitlabCom, feature_category: :global_search do
  let(:settings) { table(:application_settings) }

  describe "#up" do
    it 'does nothing' do
      record = settings.create!

      expect { migrate! }.not_to change { record.reload.elasticsearch_requeue_workers }
    end

    it 'updates elasticsearch_requeue_workers when gitlab.com' do
      allow(Gitlab).to receive(:com?).and_return(true)

      record = settings.create!

      expect { migrate! }.to change { record.reload.elasticsearch_requeue_workers }.from(false).to(true)
    end
  end

  describe "#down" do
    it 'does nothing' do
      record = settings.create!(elasticsearch_requeue_workers: true)

      migrate!

      expect { schema_migrate_down! }.not_to change { record.reload.elasticsearch_requeue_workers }
    end

    it 'updates elasticsearch_requeue_workers when gitlab.com' do
      allow(Gitlab).to receive(:com?).and_return(true)

      record = settings.create!(elasticsearch_requeue_workers: true)

      migrate!

      expect { schema_migrate_down! }.to change { record.reload.elasticsearch_requeue_workers }.from(true).to(false)
    end
  end
end
