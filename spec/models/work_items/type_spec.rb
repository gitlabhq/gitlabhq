# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Type, feature_category: :team_planning do
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

    it 'has many `child_restrictions`' do
      is_expected.to have_many(:child_restrictions)
        .class_name('WorkItems::HierarchyRestriction')
        .with_foreign_key('parent_type_id')
    end

    describe 'allowed_child_types_by_name' do
      it 'defines association' do
        is_expected.to have_many(:allowed_child_types_by_name)
          .through(:child_restrictions)
          .class_name('::WorkItems::Type')
          .with_foreign_key(:child_type_id)
      end

      it 'sorts by name ascending' do
        expected_type_names = %w[Atype Ztype gtype]
        parent_type = create(:work_item_type)

        expected_type_names.shuffle.each do |name|
          create(:hierarchy_restriction, parent_type: parent_type, child_type: create(:work_item_type, name: name))
        end

        expect(parent_type.allowed_child_types_by_name.pluck(:name)).to match_array(expected_type_names)
      end
    end
  end

  describe 'callbacks' do
    describe 'after_save' do
      subject(:work_item_type) { build(:work_item_type) }

      it 'calls #clear_reactive_cache!' do
        is_expected.to receive(:clear_reactive_cache!)
        work_item_type.save!(name: 'foo')
      end
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

        expect(described_class.count).to eq(10)

        expect { type.destroy! }.not_to change(Issue, :count)
        expect(described_class.count).to eq(9)
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
      expect(Gitlab::DatabaseImporters::WorkItems::RelatedLinksRestrictionsImporter)
        .not_to receive(:upsert_restrictions)

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
        expect(Gitlab::DatabaseImporters::WorkItems::RelatedLinksRestrictionsImporter).to receive(:upsert_restrictions)

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
    let(:parent) { build_stubbed(:project) }
    let_it_be_with_reload(:work_item_type) { create(:work_item_type) }
    let_it_be_with_reload(:widget_definition) do
      create(:widget_definition, work_item_type: work_item_type, widget_type: :assignees)
    end

    subject(:supports_assignee) { work_item_type.supports_assignee?(parent) }

    it { is_expected.to be_truthy }

    context 'when the assignees widget is not supported' do
      before do
        widget_definition.update!(disabled: true)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#supports_time_tracking?' do
    let(:parent) { build_stubbed(:project) }
    let_it_be_with_reload(:work_item_type) { create(:work_item_type) }
    let_it_be_with_reload(:widget_definition) do
      create(:widget_definition, work_item_type: work_item_type, widget_type: :time_tracking)
    end

    subject(:supports_time_tracking) { work_item_type.supports_time_tracking?(parent) }

    it { is_expected.to be_truthy }

    context 'when the time tracking widget is not supported' do
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

  describe '#allowed_child_types' do
    let_it_be(:work_item_type) { create(:work_item_type) }
    let_it_be(:child_type) { create(:work_item_type) }
    let_it_be(:restriction) { create(:hierarchy_restriction, parent_type: work_item_type, child_type: child_type) }

    subject { work_item_type.allowed_child_types(cache: cached) }

    context 'when cache is true' do
      let(:cached) { true }

      before do
        allow(work_item_type).to receive(:with_reactive_cache).and_call_original
      end

      it 'returns the cached data' do
        expect(work_item_type).to receive(:with_reactive_cache)
        expect(Rails.cache).to receive(:exist?).with("work_items_type:#{work_item_type.id}:alive")
        is_expected.to eq([child_type])
      end
    end

    context 'when cache is false' do
      let(:cached) { false }

      it 'returns queried data' do
        expect(work_item_type).not_to receive(:with_reactive_cache)
        is_expected.to eq([child_type])
      end
    end
  end

  describe '#calculate_reactive_cache' do
    let(:work_item_type) { build(:work_item_type) }

    subject { work_item_type.calculate_reactive_cache }

    it 'returns cache data for allowed child types' do
      child_types = create_list(:work_item_type, 2)
      expect(work_item_type).to receive(:allowed_child_types_by_name).and_return(child_types)

      is_expected.to eq(child_types)
    end
  end
end
