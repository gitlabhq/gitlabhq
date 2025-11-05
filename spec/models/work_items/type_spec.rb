# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Type, feature_category: :team_planning do
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

    describe '#allowed_child_types_by_name' do
      it 'returns child types from hierarchy restrictions' do
        epic_type = described_class.find_by(base_type: :epic)
        issue_type = described_class.find_by(base_type: :issue)

        expect(epic_type.allowed_child_types_by_name).to include(issue_type)
      end

      it 'returns empty array when no child types are defined' do
        custom_type = create(:work_item_type, :non_default)

        expect(custom_type.allowed_child_types_by_name).to be_empty
      end

      it 'sorts by name ascending' do
        issue_type = described_class.find_by(base_type: :issue)

        names = issue_type.allowed_child_types_by_name.pluck(:name)
        expect(names).to eq(names.sort_by(&:downcase))
      end
    end

    describe '#allowed_parent_types_by_name' do
      it 'returns parent types from hierarchy restrictions' do
        task_type = described_class.find_by(base_type: :task)
        issue_type = described_class.find_by(base_type: :issue)

        expect(task_type.allowed_parent_types_by_name).to include(issue_type)
      end

      it 'returns empty array when no parent types are defined' do
        custom_type = create(:work_item_type, :non_default)

        expect(custom_type.allowed_parent_types_by_name).to be_empty
      end

      it 'sorts by name ascending' do
        task_type = described_class.find_by(base_type: :task)

        names = task_type.allowed_parent_types_by_name.pluck(:name)
        expect(names).to eq(names.sort)
      end
    end
  end

  describe 'scopes' do
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

  describe '.default_by_type' do
    let(:default_issue_type) { described_class.find_by(base_type: :issue) }
    let(:base_type) { :issue }

    subject { described_class.default_by_type(base_type) }

    it 'returns default work item type by base type without calling importer' do
      expect(Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter).not_to receive(:upsert_types).and_call_original
      expect(Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter).not_to receive(:upsert_widgets)

      is_expected.to eq(default_issue_type)
    end

    context 'when default types are missing' do
      before do
        described_class.delete_all
      end

      subject(:default_by_type) { described_class.default_by_type(base_type) }

      it 'raises an error' do
        expect do
          default_by_type
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
            default_by_type
          end.not_to raise_error
        end
      end
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

  describe '#allowed_child_types' do
    let_it_be(:epic_type) { described_class.find_by(base_type: :epic) }
    let_it_be(:issue_type) { described_class.find_by(base_type: :issue) }

    subject { epic_type.allowed_child_types }

    it 'returns queried data' do
      is_expected.to include(issue_type) # Changed from expect(subject)
    end
  end

  describe '#allowed_parent_types' do
    let_it_be(:issue_type) { described_class.find_by(base_type: :issue) }
    let_it_be(:epic_type) { described_class.find_by(base_type: :epic) }

    subject { issue_type.allowed_parent_types }

    it 'returns queried data' do
      is_expected.to include(epic_type)
    end
  end

  describe '#descendant_types' do
    let(:epic_type) { described_class.find_by(base_type: :epic) }
    let(:issue_type) { described_class.find_by(base_type: :issue) }
    let(:task_type) { described_class.find_by(base_type: :task) }

    subject(:descendant_types) { epic_type.descendant_types }

    it 'returns all possible descendant types' do
      is_expected.to include(epic_type, issue_type, task_type)
    end

    it 'handles circular dependencies correctly' do
      expect { descendant_types }.not_to raise_error
    end
  end

  describe '.allowed_group_level_types' do
    let_it_be(:group) { create(:group) }

    subject { described_class.allowed_group_level_types(group) }

    it { is_expected.to be_empty }
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
        is_expected.to include(incident_type, task_type, ticket_type)
        is_expected.not_to include(issue_type)
      end
    end

    context 'when work item type is incident' do
      let(:work_item_type) { incident_type }

      it 'returns all supported types except itself' do
        is_expected.to include(issue_type, task_type, ticket_type)
        is_expected.not_to include(incident_type)
      end
    end

    context 'when work item type is epic' do
      let(:work_item_type) { create(:work_item_type, :epic) }

      it 'does not include epic as it is excluded from supported conversion types' do
        is_expected.not_to include(work_item_type)
      end
    end

    context 'when work item type is objective' do
      let(:work_item_type) { create(:work_item_type, :objective) }

      it 'returns empty array as objective is excluded from supported conversion types' do
        is_expected.not_to include(work_item_type)
      end
    end

    context 'when resource_parent is provided' do
      let(:work_item_type) { issue_type }

      it 'passes resource_parent to supported_conversion_base_types' do
        expect(work_item_type).to receive(:supported_conversion_base_types)
          .with(resource_parent, developer_user)
          .and_call_original

        work_item_type.supported_conversion_types(resource_parent, developer_user)
      end
    end
  end
end
