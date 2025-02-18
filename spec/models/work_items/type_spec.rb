# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Type, feature_category: :team_planning do
  shared_examples 'a model that uses correct_id/id as global id' do
    it 'uses the correct_id column for global ids' do
      expect(
        GlobalID.new(type.public_send(gid_method).to_s).model_id.to_i
      ).to eq(type.attributes['correct_id'])
    end
  end

  describe 'modules' do
    it { is_expected.to include_module(CacheMarkdownField) }
  end

  describe 'associations' do
    it 'has many `widget_definitions`' do
      is_expected.to have_many(:widget_definitions)
        .class_name('::WorkItems::WidgetDefinition')
        .with_foreign_key('work_item_type_id')
    end

    it 'has many `enabled_widget_definitions`' do
      type = create(:work_item_type, :non_default)
      widget1 = create(:widget_definition, work_item_type: type, name: 'Enabled widget')
      create(:widget_definition, work_item_type: type, disabled: true, name: 'Disabled widget')

      expect(type.enabled_widget_definitions).to match_array([widget1])
    end

    it 'has many `child_restrictions`' do
      is_expected.to have_many(:child_restrictions)
        .class_name('WorkItems::HierarchyRestriction')
        .with_foreign_key('parent_type_id')
    end

    it 'has many `parent_restrictions`' do
      is_expected.to have_many(:parent_restrictions)
        .class_name('WorkItems::HierarchyRestriction')
        .with_foreign_key('child_type_id')
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
        parent_type = create(:work_item_type, :non_default)

        expected_type_names.shuffle.each do |name|
          create(
            :hierarchy_restriction,
            parent_type: parent_type,
            child_type: create(:work_item_type, :non_default, name: name)
          )
        end

        expect(parent_type.allowed_child_types_by_name.pluck(:name)).to match_array(expected_type_names)
      end
    end

    describe 'allowed_parent_types_by_name' do
      it 'defines association' do
        is_expected.to have_many(:allowed_parent_types_by_name)
          .through(:parent_restrictions)
          .class_name('::WorkItems::Type')
          .with_foreign_key(:parent_type_id)
      end

      it 'sorts by name ascending' do
        expected_type_names = %w[Atype Ztype gtype]
        child_type = create(:work_item_type, :non_default)

        expected_type_names.shuffle.each do |name|
          create(
            :hierarchy_restriction,
            parent_type: create(:work_item_type, :non_default, name: name),
            child_type: child_type
          )
        end

        expect(child_type.allowed_parent_types_by_name.pluck(:name)).to match_array(expected_type_names)
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
    describe 'with_correct_id_and_fallback' do
      let_it_be(:type1) do
        create(:work_item_type, :non_default).tap { |type| type.update!(old_id: type.id * 10, id: -type.id) }
      end

      let_it_be(:type2) do
        create(:work_item_type, :non_default).tap { |type| type.update!(old_id: type.id * 10, id: -type.id) }
      end

      let_it_be(:type3) do
        create(:work_item_type, :non_default).tap { |type| type.update!(old_id: type2.correct_id, id: -type.id) }
      end

      subject { described_class.with_correct_id_and_fallback(ids_for_scope) }

      context 'when ids are null' do
        let(:ids_for_scope) { nil }

        it { is_expected.to be_empty }
      end

      context 'when ids are empty array' do
        let(:ids_for_scope) { [] }

        it { is_expected.to be_empty }
      end

      context 'when using old ids' do
        let(:ids_for_scope) { [type1, type2].map(&:old_id) }

        it { is_expected.to contain_exactly(type1, type2) }
      end

      context 'when using correct ids' do
        let(:ids_for_scope) { [type1, type2].map(&:correct_id) }

        # type3 only gets matched because it's old_id matches type2.correct_id
        it { is_expected.to contain_exactly(type1, type2, type3) }
      end

      context 'when using correct ids but another type has the same old_id value' do
        let(:ids_for_scope) { [type2].map(&:correct_id) }

        it { is_expected.to contain_exactly(type2, type3) }
      end

      context 'when using ids' do
        let(:ids_for_scope) { [type1, type2].map(&:id) }

        it { is_expected.to be_empty }
      end
    end

    describe 'order_by_name_asc' do
      subject { described_class.order_by_name_asc.pluck(:name) }

      before do
        # Deletes all so we have control on the entire list of names
        described_class.delete_all
        create(:work_item_type, :non_default, name: 'Ztype')
        create(:work_item_type, :non_default, name: 'atype')
        create(:work_item_type, :non_default, name: 'gtype')
      end

      it { is_expected.to match(%w[atype gtype Ztype]) }
    end
  end

  describe '#destroy' do
    let!(:work_item) { create :issue }

    context 'when there are no work items of that type' do
      it 'deletes type but not unrelated issues' do
        type = create(:work_item_type, :non_default)

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
      it 'validates uniqueness with a custom validator' do
        create(:work_item_type, :non_default, name: 'Test Type')

        new_type = build(:work_item_type, :non_default, name: ' TesT Type ')
        expect(new_type).to be_invalid
        expect(new_type.errors.full_messages).to include('Name has already been taken')
      end
    end

    it { is_expected.not_to allow_value('s' * 256).for(:icon_name) }
  end

  describe '.find_by_correct_id_with_fallback' do
    let_it_be(:type1) do
      create(:work_item_type, :non_default).tap { |type| type.update!(old_id: type.id * 10, id: -type.id) }
    end

    let_it_be(:type2) do
      create(:work_item_type, :non_default).tap { |type| type.update!(old_id: type.id * 10, id: -type.id) }
    end

    let_it_be(:type3) do
      create(:work_item_type, :non_default).tap { |type| type.update!(old_id: type2.correct_id, id: -type.id) }
    end

    subject { described_class.find_by_correct_id_with_fallback(id_input) }

    context 'when fetching by correct_id' do
      let(:id_input) { type1.correct_id }

      it { is_expected.to eq(type1) }
    end

    context 'when fetching by old_id' do
      let(:id_input) { type1.old_id }

      it { is_expected.to eq(type1) }
    end

    context 'when fetching by correct_id but an old_id matches the value' do
      let(:id_input) { type3.old_id }

      it { is_expected.to eq(type2) }
    end
  end

  describe '.default_by_type' do
    let(:default_issue_type) { described_class.find_by(base_type: :issue) }
    let(:base_type) { :issue }

    subject { described_class.default_by_type(base_type) }

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

      it 'raises an error' do
        expect do
          subject
        end.to raise_error(
          WorkItems::Type::DEFAULT_TYPES_NOT_SEEDED,
          <<~STRING
            Default work item types have not been created yet. Make sure the DB has been seeded successfully.
            See related documentation in
            https://docs.gitlab.com/omnibus/settings/database.html#seed-the-database-fresh-installs-only

            If you have additional questions, you can ask in
            https://gitlab.com/gitlab-org/gitlab/-/issues/423483
          STRING
        )
      end

      context 'when an invalid issue_type is passed' do
        let(:base_type) { :invalid_type }

        it { is_expected.to be_nil }

        it 'does not raise an error' do
          expect do
            subject
          end.not_to raise_error
        end
      end
    end
  end

  describe '#to_global_id' do
    it_behaves_like 'a model that uses correct_id/id as global id' do
      let(:type) { described_class.first }
      let(:gid_method) { :to_global_id }
    end
  end

  describe '#to_gid' do
    it_behaves_like 'a model that uses correct_id/id as global id' do
      let(:type) { described_class.first }
      let(:gid_method) { :to_gid }
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
    let_it_be_with_reload(:work_item_type) { create(:work_item_type, :non_default) }
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
    let_it_be_with_reload(:work_item_type) { create(:work_item_type, :non_default) }
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
      let(:work_item_type) { build(:work_item_type, :non_default) }

      it 'returns false' do
        expect(work_item_type.default_issue?).to be(false)
      end
    end
  end

  describe '#allowed_child_types' do
    let_it_be(:work_item_type) { create(:work_item_type, :non_default) }
    let_it_be(:child_type) { create(:work_item_type, :non_default) }
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

  describe '#allowed_parent_types' do
    let_it_be(:work_item_type) { create(:work_item_type, :non_default) }
    let_it_be(:parent_type) { create(:work_item_type, :non_default) }
    let_it_be(:restriction) { create(:hierarchy_restriction, parent_type: parent_type, child_type: work_item_type) }

    subject { work_item_type.allowed_parent_types(cache: cached) }

    context 'when cache is true' do
      let(:cached) { true }

      before do
        allow(work_item_type).to receive(:with_reactive_cache).and_call_original
      end

      it 'returns the cached data' do
        expect(work_item_type).to receive(:with_reactive_cache)
        expect(Rails.cache).to receive(:exist?).with("work_items_type:#{work_item_type.id}:alive")
        is_expected.to eq([parent_type])
      end
    end

    context 'when cache is false' do
      let(:cached) { false }

      it 'returns queried data' do
        expect(work_item_type).not_to receive(:with_reactive_cache)
        is_expected.to eq([parent_type])
      end
    end
  end

  describe '#descendant_types' do
    let(:epic_type) { create(:work_item_type, :non_default) }
    let(:issue_type) { create(:work_item_type, :non_default) }
    let(:task_type) { create(:work_item_type, :non_default) }

    subject { epic_type.descendant_types }

    before do
      create(:hierarchy_restriction, parent_type: epic_type, child_type: epic_type)
      create(:hierarchy_restriction, parent_type: epic_type, child_type: issue_type)
      create(:hierarchy_restriction, parent_type: issue_type, child_type: task_type)
    end

    it 'returns all possible descendant types' do
      is_expected.to contain_exactly(epic_type, issue_type, task_type)
    end
  end

  describe '#calculate_reactive_cache' do
    let(:work_item_type) { build(:work_item_type) }

    subject { work_item_type.calculate_reactive_cache }

    it 'returns cache data for allowed child types' do
      child_types = create_list(:work_item_type, 2)
      parent_types = create_list(:work_item_type, 2)
      cache_data = { allowed_child_types_by_name: child_types, allowed_parent_types_by_name: parent_types }

      expect(work_item_type).to receive(:allowed_child_types_by_name).and_return(child_types)
      expect(work_item_type).to receive(:allowed_parent_types_by_name).and_return(parent_types)

      is_expected.to eq(cache_data)
    end
  end

  describe '.allowed_group_level_types' do
    let_it_be(:group) { create(:group) }
    let_it_be(:non_ee_types) { described_class.base_types.keys.excluding('epic') }

    subject { described_class.allowed_group_level_types(group) }

    it { is_expected.to include(*non_ee_types) }

    context 'when create_group_level_work_items feature flag is disabled' do
      before do
        stub_feature_flags(create_group_level_work_items: false)
      end

      it { is_expected.to be_empty }
    end
  end

  describe '#supported_conversion_types' do
    let_it_be(:developer_user) { create(:user) }
    let_it_be(:resource_parent) { create(:project) }
    let_it_be(:issue_type) { create(:work_item_type, :issue) }
    let_it_be(:incident_type) { create(:work_item_type, :incident) }
    let_it_be(:task_type) { create(:work_item_type, :task) }
    let_it_be(:ticket_type) { create(:work_item_type, :ticket) }

    before_all do
      resource_parent.add_developer(developer_user)
    end

    subject { work_item_type.supported_conversion_types(resource_parent, developer_user) }

    context 'when work item type is issue' do
      let(:work_item_type) { issue_type }

      it 'returns all supported types except itself' do
        expect(subject).to include(incident_type, task_type, ticket_type)
        expect(subject).not_to include(issue_type)
      end
    end

    context 'when work item type is incident' do
      let(:work_item_type) { incident_type }

      it 'returns all supported types except itself' do
        expect(subject).to include(issue_type, task_type, ticket_type)
        expect(subject).not_to include(incident_type)
      end
    end

    context 'when work item type is epic' do
      let(:work_item_type) { create(:work_item_type, :epic) }

      it 'does not include epic as it is excluded from supported conversion types' do
        expect(subject).not_to include(work_item_type)
      end
    end

    context 'when work item type is objective' do
      let(:work_item_type) { create(:work_item_type, :objective) }

      it 'returns empty array as objective is excluded from supported conversion types' do
        expect(subject).not_to include(work_item_type)
      end
    end

    context 'when resource_parent is provided' do
      let(:work_item_type) { issue_type }

      it 'passes resource_parent to supported_conversion_base_types' do
        expect(work_item_type).to receive(:supported_conversion_base_types)
          .with(resource_parent, developer_user)
          .and_call_original

        subject
      end
    end
  end
end
