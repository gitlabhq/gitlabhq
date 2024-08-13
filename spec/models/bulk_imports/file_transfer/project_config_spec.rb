# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FileTransfer::ProjectConfig, feature_category: :importers do
  let_it_be(:exportable) { create(:project) }
  let_it_be(:hex) { '123' }

  before do
    allow(SecureRandom).to receive(:hex).and_return(hex)
  end

  subject { described_class.new(exportable) }

  describe 'portable_tree' do
    it 'returns portable tree' do
      expect_next_instance_of(::Gitlab::ImportExport::AttributesFinder) do |finder|
        expect(finder).to receive(:find_root).with(:project).and_call_original
      end

      expect(subject.portable_tree).not_to be_empty
    end
  end

  describe '#export_path' do
    it 'returns tmpdir location' do
      expect(subject.export_path).to include(File.join(Dir.tmpdir, 'bulk_imports'))
    end
  end

  describe '#portable_relations' do
    it 'returns a list of top level exportable relations' do
      expect(subject.portable_relations).to include('issues', 'labels', 'milestones', 'merge_requests')
    end

    it 'does not include skipped relations' do
      expect(subject.portable_relations).not_to include('project_members', 'group_members')
    end
  end

  describe '#top_relation_tree' do
    it 'returns relation tree of a top level relation' do
      expect(subject.top_relation_tree('labels')).to eq('priorities' => {})
    end

    it 'returns relation tree with merged with deprecated tree' do
      expect(subject.top_relation_tree('ci_pipelines')).to match(
        a_hash_including(
          {
            'external_pull_request' => {},
            'merge_request' => {},
            'stages' => { 'bridges' => {}, 'builds' => {}, 'generic_commit_statuses' => {}, 'statuses' => {} }
          }
        )
      )
    end
  end

  describe '#relation_excluded_keys' do
    it 'returns excluded keys for relation' do
      expect(subject.relation_excluded_keys('project')).to include('creator_id')
    end
  end

  describe '#relation_included_keys' do
    it 'returns included keys for relation' do
      expect(subject.relation_included_keys('project')).to include('approvals_before_merge')
    end
  end

  describe '#tree_relation?' do
    context 'when it is a tree relation' do
      it 'returns true' do
        expect(subject.tree_relation?('labels')).to eq(true)
      end
    end

    context 'when it is not a tree relation' do
      it 'returns false' do
        expect(subject.tree_relation?('example')).to eq(false)
      end
    end
  end

  describe '#file_relation?' do
    context 'when it is a file relation' do
      it 'returns true' do
        expect(subject.file_relation?('uploads')).to eq(true)
      end
    end

    context 'when it is not a file relation' do
      it 'returns false' do
        expect(subject.file_relation?('example')).to eq(false)
      end
    end
  end

  describe '#relation_has_user_contributions?' do
    subject { described_class.new(exportable).relation_has_user_contributions?(relation) }

    context 'when the relation has user contribitions' do
      let(:relation) { 'issues' }

      it { is_expected.to eq(true) }
    end

    context 'when the relation does not have user contribitions' do
      let(:relation) { 'labels' }

      it { is_expected.to eq(false) }
    end
  end

  describe '#user_contributions_relation?' do
    it 'returns true for the user_contributions relation' do
      expect(subject.user_contributions_relation?('user_contributions')).to eq(true)
    end

    it 'returns false for non user_contributions relations' do
      expect(subject.user_contributions_relation?('milestones')).to eq(false)
    end
  end

  describe '#tree_relation_definition_for' do
    it 'returns relation definition' do
      expected = { service_desk_setting: { except: [:outgoing_name, :file_template_project_id], include: [], only: %i[project_id issue_template_key project_key] } }

      expect(subject.tree_relation_definition_for('service_desk_setting')).to eq(expected)
    end

    context 'when relation is not tree relation' do
      it 'returns' do
        expect(subject.tree_relation_definition_for('example')).to be_nil
      end
    end
  end

  describe '#file_relations' do
    it 'returns project file relations' do
      expect(subject.file_relations).to contain_exactly('uploads', 'lfs_objects', 'repository', 'design')
    end
  end

  describe '#batchable_relation?' do
    context 'when relation is batchable' do
      it 'returns true' do
        expect(subject.batchable_relation?('issues')).to eq(true)
      end
    end

    context 'when relation is not batchable' do
      it 'returns false' do
        expect(subject.batchable_relation?('project_feature')).to eq(false)
      end
    end

    context 'when relation is not listed as portable' do
      it 'returns false' do
        expect(subject.batchable_relation?('foo')).to eq(false)
      end
    end
  end

  describe '#batchable_relations' do
    it 'returns a list of collection associations for a project' do
      expect(subject.batchable_relations).to include('issues', 'merge_requests', 'milestones')
      expect(subject.batchable_relations).not_to include('project_feature', 'ci_cd_settings')
    end
  end
end
