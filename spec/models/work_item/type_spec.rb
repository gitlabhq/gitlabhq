# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItem::Type do
  describe 'modules' do
    it { is_expected.to include_module(CacheMarkdownField) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:work_items).with_foreign_key('work_item_type_id') }
    it { is_expected.to belong_to(:namespace) }
  end

  describe '#destroy' do
    let!(:work_item) { create :issue }

    context 'when there are no work items of that type' do
      it 'deletes type but not unrelated issues' do
        type = create(:work_item_type)

        expect { type.destroy! }.not_to change(Issue, :count)
        expect(WorkItem::Type.count).to eq 0
      end
    end

    it 'does not delete type when there are related issues' do
      type = create(:work_item_type, work_items: [work_item])

      expect { type.destroy! }.to raise_error(ActiveRecord::InvalidForeignKey)
      expect(Issue.count).to eq 1
    end
  end

  describe 'validation' do
    describe 'name uniqueness' do
      subject { create(:work_item_type) }

      it { is_expected.to validate_uniqueness_of(:name).case_insensitive.scoped_to([:namespace_id]) }
    end

    it { is_expected.not_to allow_value('s' * 256).for(:icon_name) }
  end

  describe '#name' do
    it 'strips name' do
      work_item_type = described_class.new(name: '   label😸   ')
      work_item_type.valid?

      expect(work_item_type.name).to eq('label😸')
    end
  end
end
