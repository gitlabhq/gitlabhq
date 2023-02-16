# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Type do
  describe 'modules' do
    it { is_expected.to include_module(CacheMarkdownField) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:work_items).with_foreign_key('work_item_type_id') }
    it { is_expected.to belong_to(:namespace) }

    it 'has many `widget_definitions`' do
      is_expected.to have_many(:widget_definitions)
        .class_name('::WorkItems::WidgetDefinition')
        .with_foreign_key('work_item_type_id')
    end

    it 'has many `enabled_widget_definitions`' do
      type = create(:work_item_type)
      widget1 = create(:widget_definition, work_item_type: type)
      create(:widget_definition, work_item_type: type, disabled: true)

      expect(type.enabled_widget_definitions).to match_array([widget1])
    end
  end

  describe 'scopes' do
    describe 'order_by_name_asc' do
      subject { described_class.order_by_name_asc.pluck(:name) }

      before do
        # Deletes all so we have control on the entire list of names
        described_class.delete_all
        create(:work_item_type, name: 'Ztype')
        create(:work_item_type, name: 'atype')
        create(:work_item_type, name: 'gtype')
      end

      it { is_expected.to match(%w[atype gtype Ztype]) }
    end
  end

  describe '#destroy' do
    let!(:work_item) { create :issue }

    context 'when there are no work items of that type' do
      it 'deletes type but not unrelated issues' do
        type = create(:work_item_type)

        expect(WorkItems::Type.count).to eq(8)

        expect { type.destroy! }.not_to change(Issue, :count)
        expect(WorkItems::Type.count).to eq(7)
      end
    end

    it 'does not delete type when there are related issues' do
      type = work_item.work_item_type

      expect { type.destroy! }.to raise_error(ActiveRecord::InvalidForeignKey)
      expect(Issue.count).to eq(1)
    end
  end

  describe 'validation' do
    describe 'name uniqueness' do
      subject { create(:work_item_type) }

      it { is_expected.to validate_uniqueness_of(:name).case_insensitive.scoped_to([:namespace_id]) }
    end

    it { is_expected.not_to allow_value('s' * 256).for(:icon_name) }
  end

  describe '.default_by_type' do
    let(:default_issue_type) { described_class.find_by(namespace_id: nil, base_type: :issue) }

    subject { described_class.default_by_type(:issue) }

    it 'returns default work item type by base type without calling importer' do
      expect(Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter).not_to receive(:upsert_types).and_call_original
      expect(Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter).not_to receive(:upsert_widgets)
      expect(Gitlab::DatabaseImporters::WorkItems::HierarchyRestrictionsImporter).not_to receive(:upsert_restrictions)

      expect(subject).to eq(default_issue_type)
    end

    context 'when default types are missing' do
      before do
        described_class.delete_all
      end

      it 'creates types and restrictions and returns default work item type by base type' do
        expect(Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter).to receive(:upsert_types).and_call_original
        expect(Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter).to receive(:upsert_widgets)
        expect(Gitlab::DatabaseImporters::WorkItems::HierarchyRestrictionsImporter).to receive(:upsert_restrictions)

        expect(subject).to eq(default_issue_type)
      end
    end
  end

  describe '#default?' do
    subject { build(:work_item_type, namespace: namespace).default? }

    context 'when namespace is nil' do
      let(:namespace) { nil }

      it { is_expected.to be_truthy }
    end

    context 'when namespace is present' do
      let(:namespace) { build(:namespace) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#name' do
    it 'strips name' do
      work_item_type = described_class.new(name: '   label😸   ')
      work_item_type.valid?

      expect(work_item_type.name).to eq('label😸')
    end
  end

  describe '#supports_assignee?' do
    let_it_be_with_reload(:work_item_type) { create(:work_item_type) }
    let_it_be_with_reload(:widget_definition) do
      create(:widget_definition, work_item_type: work_item_type, widget_type: :assignees)
    end

    subject(:supports_assignee) { work_item_type.supports_assignee? }

    it { is_expected.to be_truthy }

    context 'when the assignees widget is not supported' do
      before do
        widget_definition.update!(disabled: true)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#default_issue?' do
    context 'when work item type is default Issue' do
      let(:work_item_type) { build(:work_item_type, name: described_class::TYPE_NAMES[:issue]) }

      it 'returns true' do
        expect(work_item_type.default_issue?).to be(true)
      end
    end

    context 'when work item type is not Issue' do
      let(:work_item_type) { build(:work_item_type) }

      it 'returns false' do
        expect(work_item_type.default_issue?).to be(false)
      end
    end
  end
end
