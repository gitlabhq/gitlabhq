# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateTopicsSlugColumn, feature_category: :groups_and_projects do
  let(:migration) do
    described_class.new(
      start_id: topic1.id,
      end_id: topic4.id,
      batch_table: :topics,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 2.minutes,
      connection: ApplicationRecord.connection
    )
  end

  let(:organizations) { table(:organizations) }
  let(:topics) { table(:topics) }

  let!(:default_organization) { organizations.create!(id: 1, visibility_level: 0, name: 'default', path: 'path') }
  let!(:topic1) { topics.create!(name: 'dog 🐶') }
  let!(:topic2) { topics.create!(name: 'some topic') }
  let!(:topic3) { topics.create!(name: 'topic', slug: 'topic') }
  let!(:topic4) { topics.create!(name: 'topic🐶') }

  describe '#perform' do
    subject(:perform_migration) { migration.perform }

    it 'populates topics slug column' do
      expect { perform_migration }.to change { topic1.reload.slug }.from(nil)
        .and change { topic2.reload.slug }.from(nil)
          .and not_change { topic3.reload.slug } # already has slug
            .and change { topic4.reload.slug }.from(nil)
    end
  end
end
