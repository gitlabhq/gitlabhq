# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FileTransfer::GroupConfig do
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
    it 'returns correct export path' do
      expect(::Gitlab::ImportExport).to receive(:storage_path).and_return('storage_path')

      expect(subject.export_path).to eq("storage_path/#{exportable.full_path}/#{hex}")
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
      expect(subject.top_relation_tree('labels')).to eq('priorities' => {})
    end
  end

  describe '#relation_excluded_keys' do
    it 'returns excluded keys for relation' do
      expect(subject.relation_excluded_keys('group')).to include('owner_id')
    end
  end
end
