# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::RelationExport, type: :model, feature_category: :importers do
  describe 'associations' do
    it { is_expected.to belong_to(:project_export_job) }
    it { is_expected.to have_one(:upload) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project_export_job) }
    it { is_expected.to validate_presence_of(:relation) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_numericality_of(:status).only_integer }
    it { is_expected.to validate_length_of(:relation).is_at_most(255) }
    it { is_expected.to validate_length_of(:jid).is_at_most(255) }
    it { is_expected.to validate_length_of(:export_error).is_at_most(300) }

    it 'validates uniquness of the relation attribute' do
      create(:project_relation_export)
      expect(subject).to validate_uniqueness_of(:relation).scoped_to(:project_export_job_id)
    end
  end

  describe '.by_relation' do
    it 'returns export relations filtered by relation name' do
      project_relation_export_1 = create(:project_relation_export, relation: 'labels')
      project_relation_export_2 = create(:project_relation_export, relation: 'labels')
      create(:project_relation_export, relation: 'uploads')

      relations = described_class.by_relation('labels').to_a

      expect(relations).to match_array([project_relation_export_1, project_relation_export_2])
    end
  end

  describe '.relation_names_list' do
    it 'includes extra relations list' do
      expect(described_class.relation_names_list).to include(
        'design_repository', 'lfs_objects', 'repository', 'snippets_repository', 'uploads', 'wiki_repository'
      )
    end

    it 'includes root tree relation name project' do
      expect(described_class.relation_names_list).to include('project')
    end

    it 'includes project tree top level relation nodes' do
      expect(described_class.relation_names_list).to include('milestones', 'issues', 'snippets', 'releases')
    end

    it 'includes project tree nested relation nodes' do
      expect(described_class.relation_names_list).not_to include('events', 'notes')
    end
  end

  describe '#mark_as_failed' do
    it 'sets status to failed and sets the export error', :aggregate_failures do
      relation_export = create(:project_relation_export)

      relation_export.mark_as_failed("Error message")
      relation_export.reload

      expect(relation_export.failed?).to eq(true)
      expect(relation_export.export_error).to eq("Error message")
    end
  end
end
