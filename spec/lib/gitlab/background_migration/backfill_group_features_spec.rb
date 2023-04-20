# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillGroupFeatures, :migration, schema: 20220314184009 do
  let(:group_features) { table(:group_features) }
  let(:namespaces) { table(:namespaces) }

  subject do
    described_class.new(start_id: 1,
                        end_id: 4,
                        batch_table: :namespaces,
                        batch_column: :id,
                        sub_batch_size: 10,
                        pause_ms: 0,
                        job_arguments: [4],
                        connection: ActiveRecord::Base.connection)
  end

  describe '#perform' do
    it 'creates settings for all group namespaces in range' do
      namespaces.create!(id: 1, name: 'group1', path: 'group1', type: 'Group')
      namespaces.create!(id: 2, name: 'user', path: 'user')
      namespaces.create!(id: 3, name: 'group2', path: 'group2', type: 'Group')

      # Checking that no error is raised if the group_feature for a group already exists
      namespaces.create!(id: 4, name: 'group3', path: 'group3', type: 'Group')
      group_features.create!(id: 1, group_id: 4)
      expect(group_features.count).to eq 1

      expect { subject.perform }.to change { group_features.count }.by(2)

      expect(group_features.count).to eq 3
      expect(group_features.all.pluck(:group_id)).to contain_exactly(1, 3, 4)
    end
  end
end
