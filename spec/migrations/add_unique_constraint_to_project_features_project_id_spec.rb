require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180511174224_add_unique_constraint_to_project_features_project_id.rb')

describe AddUniqueConstraintToProjectFeaturesProjectId, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:features) { table(:project_features) }
  let(:migration) { described_class.new }

  describe '#up' do
    before do
      (1..3).each do |i|
        namespaces.create(id: i, name: "ns-test-#{i}", path: "ns-test-i#{i}")
        projects.create!(id: i, name: "test-#{i}", path: "test-#{i}", namespace_id: i)
      end

      features.create!(id: 1, project_id: 1)
      features.create!(id: 2, project_id: 1)
      features.create!(id: 3, project_id: 2)
      features.create!(id: 4, project_id: 2)
      features.create!(id: 5, project_id: 2)
      features.create!(id: 6, project_id: 3)
    end

    it 'creates a unique index and removes duplicates' do
      expect(migration.index_exists?(:project_features, :project_id, unique: false, name: 'index_project_features_on_project_id')).to be true

      expect { migration.up }.to change { features.count }.from(6).to(3)

      expect(migration.index_exists?(:project_features, :project_id, unique: true, name: 'index_project_features_on_project_id')).to be true
      expect(migration.index_exists?(:project_features, :project_id, name: 'index_project_features_on_project_id_unique')).to be false

      project_1_features = features.where(project_id: 1)
      expect(project_1_features.count).to eq(1)
      expect(project_1_features.first.id).to eq(2)

      project_2_features = features.where(project_id: 2)
      expect(project_2_features.count).to eq(1)
      expect(project_2_features.first.id).to eq(5)

      project_3_features = features.where(project_id: 3)
      expect(project_3_features.count).to eq(1)
      expect(project_3_features.first.id).to eq(6)
    end
  end

  describe '#down' do
    it 'restores the original index' do
      migration.up

      expect(migration.index_exists?(:project_features, :project_id, unique: true, name: 'index_project_features_on_project_id')).to be true

      migration.down

      expect(migration.index_exists?(:project_features, :project_id, unique: false, name: 'index_project_features_on_project_id')).to be true
      expect(migration.index_exists?(:project_features, :project_id, name: 'index_project_features_on_project_id_old')).to be false
    end
  end
end
