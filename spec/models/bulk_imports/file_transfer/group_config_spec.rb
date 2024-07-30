# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FileTransfer::GroupConfig, feature_category: :importers do
  let_it_be(:exportable) { create(:group) }
  let_it_be(:hex) { '123' }

  before do
    allow(SecureRandom).to receive(:hex).and_return(hex)
  end

  subject { described_class.new(exportable) }

  describe '#portable_tree' do
    it 'returns portable tree' do
      expect_next_instance_of(::Gitlab::ImportExport::AttributesFinder) do |finder|
        expect(finder).to receive(:find_root).with(:group).and_call_original
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
      expect(subject.portable_relations).to include('milestones', 'badges', 'boards', 'labels')
    end

    it 'does not include skipped relations' do
      expect(subject.portable_relations).not_to include('members')
    end
  end

  describe '#top_relation_tree' do
    it 'returns relation tree of a top level relation' do
      expect(subject.top_relation_tree('boards')).to include(
        'lists' => a_hash_including({
          'board' => anything,
          'label' => anything
        })
      )
    end
  end

  describe '#relation_excluded_keys' do
    it 'returns excluded keys for relation' do
      expect(subject.relation_excluded_keys('group')).to include('owner_id')
    end
  end

  describe '#relation_included_keys' do
    it 'returns included keys for relation' do
      expect(subject.relation_included_keys('user')).to include('id')
    end
  end

  describe '#batchable_relation?' do
    context 'when relation is batchable' do
      it 'returns true' do
        expect(subject.batchable_relation?('labels')).to eq(true)
      end
    end

    context 'when relation is not batchable' do
      it 'returns false' do
        expect(subject.batchable_relation?('namespace_settings')).to eq(false)
      end
    end

    context 'when relation is not listed as portable' do
      it 'returns false' do
        expect(subject.batchable_relation?('foo')).to eq(false)
      end
    end
  end

  describe '#batchable_relations' do
    it 'returns a list of collection associations for a group' do
      expect(subject.batchable_relations).to include('labels', 'boards', 'milestones')
      expect(subject.batchable_relations).not_to include('namespace_settings')
    end
  end

  describe '#export_service_for' do
    context 'when relation is a tree' do
      it 'returns TreeExportService' do
        expect(subject.export_service_for('labels')).to eq(BulkImports::TreeExportService)
      end
    end

    context 'when relation is a file' do
      it 'returns FileExportService' do
        expect(subject.export_service_for('uploads')).to eq(BulkImports::FileExportService)
      end
    end

    context 'when relation is unknown' do
      it 'raises' do
        expect { subject.export_service_for('foo') }.to raise_error(BulkImports::Error, 'Unsupported export relation')
      end
    end
  end

  describe '#relation_has_user_contributions?' do
    subject { described_class.new(exportable).relation_has_user_contributions?(relation) }

    let(:relation) { 'iterations' }

    context 'when the relation has user contribitions' do
      before do
        # No group imports have user contribitions
        allow_next_instance_of(::Gitlab::ImportExport::AttributesFinder) do |instance|
          allow(instance).to receive(:find_included_keys).with(relation).and_return(%w[author_id start_date])
        end
      end

      it { is_expected.to eq(true) }
    end

    context 'when the relation does not have user contribitions' do
      it { is_expected.to eq(false) }
    end
  end
end
