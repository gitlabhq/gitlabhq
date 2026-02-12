# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::TypesFramework::SystemDefined::Type, feature_category: :team_planning do
  describe 'constants and attributes' do
    describe '.fixed_items' do
      it 'includes Issue type with correct attributes' do
        issue_type = described_class.fixed_items.find { |item| item[:id] == 1 }

        expect(issue_type).to include(
          id: 1,
          name: 'Issue',
          base_type: 'issue',
          icon_name: 'work-item-issue'
        )
      end

      it 'includes Incident type with correct attributes' do
        incident_type = described_class.fixed_items.find { |item| item[:id] == 2 }

        expect(incident_type).to include(
          id: 2,
          name: 'Incident',
          base_type: 'incident',
          icon_name: 'work-item-incident'
        )
      end

      it 'includes Task type with correct attributes' do
        task_type = described_class.fixed_items.find { |item| item[:id] == 5 }

        expect(task_type).to include(
          id: 5,
          name: 'Task',
          base_type: 'task',
          icon_name: 'work-item-task'
        )
      end

      it 'includes Ticket type with correct attributes' do
        ticket_type = described_class.fixed_items.find { |item| item[:id] == 9 }

        expect(ticket_type).to include(
          id: 9,
          name: 'Ticket',
          base_type: 'ticket',
          icon_name: 'work-item-ticket'
        )
      end

      it 'has unique IDs for all types' do
        ids = described_class.fixed_items.pluck(:id)

        expect(ids.uniq.size).to eq(ids.size)
      end

      it 'has unique base_types for all types' do
        base_types = described_class.fixed_items.pluck(:base_type)

        expect(base_types.uniq.size).to eq(base_types.size)
      end
    end

    describe 'attributes' do
      let(:type) { build(:work_item_system_defined_type) } # Issue type

      it 'has name attribute' do
        expect(type.name).to eq('Issue')
      end

      it 'has base_type attribute' do
        expect(type.base_type).to eq('issue')
      end

      it 'has icon_name attribute' do
        expect(type.icon_name).to eq('work-item-issue')
      end
    end
  end

  describe 'class methods' do
    describe '.by_type' do
      it 'finds issue type by base_type' do
        result = described_class.by_type(:issue)

        expect(result.count).to eq(1)
        expect(result.first.name).to eq('Issue')
        expect(result.first.base_type).to eq('issue')
      end

      it 'returns empty relation for non-existent type' do
        result = described_class.by_type(:nonexistent)

        expect(result.count).to eq(0)
      end

      it 'accepts string argument' do
        result = described_class.by_type('incident')

        expect(result.first.name).to eq('Incident')
      end

      it 'accepts an array as argument' do
        result = described_class.by_type(%w[issue incident])

        expect(result.map(&:name)).to match_array(%w[Issue Incident])
      end
    end

    describe '.find_by_type' do
      it 'finds issue type' do
        type = described_class.find_by_type(:issue)

        expect(type).to be_present
        expect(type.name).to eq('Issue')
        expect(type.base_type).to eq('issue')
      end

      it 'returns nil for non-existent type' do
        expect(described_class.find_by_type(:nonexistent)).to be_nil
      end

      it 'accepts string argument' do
        type = described_class.find_by_type('task')

        expect(type.name).to eq('Task')
      end
    end

    describe '.find_by_name' do
      it 'finds issue type' do
        type = described_class.find_by_name("Issue")

        expect(type).to be_present
        expect(type.name).to eq('Issue')
        expect(type.base_type).to eq('issue')
      end

      it 'returns nil for non-existent type' do
        expect(described_class.find_by_name("Nonexistent")).to be_nil
      end

      it 'accepts symbol as argument' do
        type = described_class.find_by_name(:Task)

        expect(type.name).to eq('Task')
      end

      it "is case sensitive" do
        expect(described_class.find_by_name("issue")).to be_nil
      end
    end

    describe '.default_by_type' do
      it 'works the same as find_by_type' do
        expect(described_class.default_by_type(:issue)).to eq(described_class.find_by_type(:issue))
      end
    end

    describe '.default_issue_type' do
      it 'returns the Issue type' do
        type = described_class.default_issue_type

        expect(type).to be_present
        expect(type.name).to eq('Issue')
        expect(type.base_type).to eq('issue')
        expect(type.id).to eq(1)
      end
    end

    describe '.order_by_name_asc' do
      let(:mock_types) do
        [
          described_class.new(id: 1, name: 'Zebra', base_type: 'zebra', icon_name: 'icon-zebra'),
          described_class.new(id: 2, name: 'apple', base_type: 'apple', icon_name: 'icon-apple'),
          described_class.new(id: 3, name: 'Banana', base_type: 'banana', icon_name: 'icon-banana'),
          described_class.new(id: 4, name: 'cherry', base_type: 'cherry', icon_name: 'icon-cherry')
        ]
      end

      before do
        allow(described_class).to receive(:all).and_return(mock_types)
      end

      it 'orders types alphabetically by name (case-insensitive)' do
        ordered = described_class.order_by_name_asc

        expect(ordered.map(&:name)).to eq(%w[apple Banana cherry Zebra])
      end

      it 'preserves the original type objects' do
        ordered = described_class.order_by_name_asc

        expect(ordered.first).to be_a(described_class)
        expect(ordered.first.id).to eq(2) # apple type
      end

      context 'with single type' do
        let(:mock_types) do
          [described_class.new(id: 1, name: 'Only One', base_type: 'only', icon_name: 'icon')]
        end

        it 'returns the single type' do
          ordered = described_class.order_by_name_asc

          expect(ordered.size).to eq(1)
          expect(ordered.first.name).to eq('Only One')
        end
      end

      context 'with names containing spaces' do
        let(:mock_types) do
          [
            described_class.new(id: 1, name: 'Key Result', base_type: 'key_result', icon_name: 'icon'),
            described_class.new(id: 2, name: 'Issue', base_type: 'issue', icon_name: 'icon'),
            described_class.new(id: 3, name: 'Test Case', base_type: 'test_case', icon_name: 'icon')
          ]
        end

        it 'sorts correctly with spaces' do
          ordered = described_class.order_by_name_asc

          expect(ordered.map(&:name)).to eq(['Issue', 'Key Result', 'Test Case'])
        end
      end

      context 'with actual CE types' do
        let(:mock_types) do
          [
            described_class.new(id: 9, name: 'Ticket', base_type: 'ticket', icon_name: 'issue-type-issue'),
            described_class.new(id: 1, name: 'Issue', base_type: 'issue', icon_name: 'issue-type-issue'),
            described_class.new(id: 5, name: 'Task', base_type: 'task', icon_name: 'issue-type-task'),
            described_class.new(id: 2, name: 'Incident', base_type: 'incident', icon_name: 'issue-type-incident')
          ]
        end

        it 'orders CE types correctly' do
          ordered = described_class.order_by_name_asc

          expect(ordered.map(&:name)).to eq(%w[Incident Issue Task Ticket])
          expect(ordered.map(&:id)).to eq([2, 1, 5, 9])
        end
      end
    end

    describe '.by_ids_ordered_by_name' do
      it 'returns types matching the given IDs' do
        result = described_class.by_ids_ordered_by_name([1, 2, 5, 9])

        expect(result.map(&:id)).to eq([2, 1, 5, 9])
        expect(result.map(&:name)).to eq(%w[Incident Issue Task Ticket])
      end

      it 'returns empty array when no IDs match' do
        result = described_class.by_ids_ordered_by_name([999, 1000])

        expect(result).to be_empty
      end

      it 'returns empty array when given empty array' do
        result = described_class.by_ids_ordered_by_name([])

        expect(result).to be_empty
      end

      it 'handles single ID' do
        result = described_class.by_ids_ordered_by_name([1])

        expect(result.size).to eq(1)
        expect(result.first.id).to eq(1)
      end

      it 'ignores duplicate IDs' do
        result = described_class.by_ids_ordered_by_name([1, 1, 2, 2])

        expect(result.map(&:id)).to match_array([1, 2])
      end

      it 'sorts case-insensitively' do
        # All types with mixed case names
        result = described_class.by_ids_ordered_by_name([1, 2, 5, 9])
        names = result.map(&:name)

        expect(names).to eq(names.sort_by(&:downcase))
      end
    end

    describe '.by_base_type_ordered_by_name' do
      it 'orders results by name ascending (case-insensitive)' do
        result = described_class.by_base_type_ordered_by_name([:issue, :task, :incident, :ticket])
        names = result.map(&:name)

        # Expected order: Incident, Issue, Task, Ticket
        expect(names).to eq(%w[Incident Issue Task Ticket])
      end

      it 'returns empty array when no base_types match' do
        result = described_class.by_base_type_ordered_by_name([:nonexistent, :fake])

        expect(result).to be_empty
      end

      it 'returns empty array when given empty array' do
        result = described_class.by_base_type_ordered_by_name([])

        expect(result).to be_empty
      end

      it 'handles single base_type' do
        result = described_class.by_base_type_ordered_by_name([:issue])

        expect(result.size).to eq(1)
        expect(result.first.base_type).to eq('issue')
      end

      it 'accepts string base_types' do
        result = described_class.by_base_type_ordered_by_name(%w[issue task])

        expect(result.map(&:base_type)).to match_array(%w[issue task])
      end

      it 'accepts mixed symbols and strings' do
        result = described_class.by_base_type_ordered_by_name([:issue, 'task'])

        expect(result.map(&:base_type)).to match_array(%w[issue task])
      end

      it 'sorts case-insensitively' do
        all_types = [:issue, :incident, :task, :ticket]
        result = described_class.by_base_type_ordered_by_name(all_types)
        names = result.map(&:name)

        expect(names).to eq(names.sort_by(&:downcase))
      end

      it 'ignores duplicate base_types' do
        result = described_class.by_base_type_ordered_by_name([:issue, :issue, :task, :task])

        expect(result.map(&:base_type)).to match_array(%w[issue task])
      end

      it 'maintains order when base_types are provided in different order' do
        result1 = described_class.by_base_type_ordered_by_name([:task, :incident, :issue])
        result2 = described_class.by_base_type_ordered_by_name([:issue, :incident, :task])

        expect(result1.map(&:name)).to eq(result2.map(&:name))
      end
    end

    describe '.with_widget_definition' do
      let(:assignees_widget_type) { :assignees }
      let(:description_widget_type) { :description }
      let(:non_existent_widget_type) { :non_existent_widget }

      it 'returns types that have the specified widget definition' do
        types = described_class.with_widget_definition(assignees_widget_type)

        expect(types).to be_present
        expect(types).to all(be_a(described_class))
      end

      it 'only returns types with the specified widget' do
        types = described_class.with_widget_definition(assignees_widget_type)

        types.each do |type|
          widget_defs = WorkItems::TypesFramework::SystemDefined::WidgetDefinition
            .where(work_item_type_id: type.id, widget_type: assignees_widget_type.to_s)

          expect(widget_defs).to be_present
        end
      end

      it 'returns empty array when no types have the widget' do
        types = described_class.with_widget_definition(non_existent_widget_type)

        expect(types).to be_empty
      end

      it 'accepts string widget type' do
        types = described_class.with_widget_definition('description')

        expect(types).to be_present
      end

      it 'returns different results for different widgets' do
        types_with_assignees = described_class.with_widget_definition(:assignees)
        types_with_description = described_class.with_widget_definition(:description)

        # Both should have results but they might be different sets
        expect(types_with_assignees).to be_present
        expect(types_with_description).to be_present
      end
    end
  end

  describe 'GlobalID integration' do
    let(:issue_type) { described_class.find(1) }
    let(:gid) { issue_type.to_global_id }

    describe '#to_global_id' do
      it 'returns a GlobalID' do
        expect(gid).to be_a(URI::GID)
      end

      it 'uses WorkItems::Type as model_name for legacy format' do
        expect(gid.model_name).to eq('WorkItems::Type')
      end

      it 'includes the correct ID' do
        expect(gid.model_id).to eq('1')
      end

      it 'generates correct URI format' do
        expect(gid.to_s).to include('gid://gitlab/WorkItems::Type/1')
      end

      it 'works for different types' do
        task_type = described_class.find(5)
        gid = task_type.to_global_id

        expect(gid.model_id).to eq('5')
      end
    end

    describe '#to_gid' do
      it 'returns the same result as to_global_id' do
        expect(issue_type.to_gid).to eq(issue_type.to_global_id)
      end
    end
  end

  describe 'dynamically defined predicate methods' do
    # Get all available types from the fixed_items configuration
    let(:all_types) { described_class.all }
    let(:type_names) { all_types.map(&:base_type) }

    it 'defines predicate methods for all work item types' do
      # Verify that predicate methods are defined for each type
      type_names.each do |type_name|
        expect(described_class.all.first).to respond_to(:"#{type_name}?")
      end
    end

    context 'when verifying all types have unique predicates' do
      it 'ensures each type only returns true for its own predicate' do
        all_types.each do |type|
          type_names.each do |type_name|
            predicate_result = type.public_send(:"#{type_name}?")

            if type.base_type == type_name
              expect(predicate_result).to be true
            else
              expect(predicate_result).to be false
            end
          end
        end
      end
    end
  end

  describe '#widget_definitions' do
    let(:type) { build(:work_item_system_defined_type) } # Issue type

    it 'returns only widget definitions associated with this type' do
      expect(type.widget_definitions.map(&:work_item_type_id).uniq).to eq([type.id])
    end
  end

  describe '#widgets' do
    let(:type) { build(:work_item_system_defined_type) } # Issue type
    let(:resource_parent) { build(:project) }

    it 'returns a not empty array' do
      widgets = type.widgets(resource_parent)

      expect(widgets).to be_a(Array)
      expect(widgets).not_to be_empty
    end

    it 'returns only widget definitions associated with this type' do
      expect(type.widgets(resource_parent).map(&:work_item_type_id).uniq).to eq([type.id])
    end

    it 'accepts resource_parent parameter but does not use it' do
      expect { type.widgets(resource_parent) }.not_to raise_error
    end
  end

  describe '#widget_classes' do
    let(:type) { build(:work_item_system_defined_type) } # Issue type
    let(:resource_parent) { build(:project) }
    let(:description_widget_class) { WorkItems::Widgets::Description }
    let(:assignees_widget_class) { WorkItems::Widgets::Assignees }

    it 'returns an array of widget classes' do
      widget_classes = type.widget_classes(resource_parent)

      expect(widget_classes).to include(description_widget_class, assignees_widget_class)
    end
  end

  describe '#unavailable_widgets_on_conversion' do
    let(:resource_parent) { nil }
    let(:source_type) { build(:work_item_system_defined_type, :issue) }
    let(:target_type) { build(:work_item_system_defined_type, :task) }

    let(:widget_definition_class) { WorkItems::TypesFramework::SystemDefined::WidgetDefinition }
    let(:widget_1) { instance_double(widget_definition_class, widget_type: :assignees) }
    let(:widget_2) { instance_double(widget_definition_class, widget_type: :labels) }
    let(:widget_3) { instance_double(widget_definition_class, widget_type: :description) }
    let(:widget_4) { instance_double(widget_definition_class, widget_type: :milestone) }

    before do
      allow(source_type).to receive(:widgets).with(resource_parent).and_return(source_widgets)
      allow(target_type).to receive(:widgets).with(resource_parent).and_return(target_widgets)
    end

    context 'when source has widgets that target does not have' do
      let(:source_widgets) { [widget_1, widget_2, widget_3] }
      let(:target_widgets) { [widget_1, widget_3] }

      it 'returns the widgets unavailable in target type' do
        result = source_type.unavailable_widgets_on_conversion(target_type, resource_parent)

        expect(result).to contain_exactly(widget_2)
      end
    end

    context 'when target has all source widgets' do
      let(:source_widgets) { [widget_1, widget_2] }
      let(:target_widgets) { [widget_1, widget_2, widget_3] }

      it 'returns an empty array' do
        result = source_type.unavailable_widgets_on_conversion(target_type, resource_parent)

        expect(result).to be_empty
      end
    end

    context 'when target has exactly the same widgets as source' do
      let(:source_widgets) { [widget_1, widget_2] }
      let(:target_widgets) { [widget_1, widget_2] }

      it 'returns an empty array' do
        result = source_type.unavailable_widgets_on_conversion(target_type, resource_parent)

        expect(result).to be_empty
      end
    end

    context 'when target has no common widgets with source' do
      let(:source_widgets) { [widget_1, widget_2] }
      let(:target_widgets) { [widget_3, widget_4] }

      it 'returns all source widgets' do
        result = source_type.unavailable_widgets_on_conversion(target_type, resource_parent)

        expect(result).to contain_exactly(widget_1, widget_2)
      end
    end
  end

  describe '#supports_widget?' do
    let(:type) { build(:work_item_system_defined_type, :task) }
    let(:resource_parent) { build(:project) }

    context 'when the widget class is supported' do
      let(:supported_widget_class) { WorkItems::Widgets::Description }

      it 'returns true' do
        expect(type.supports_widget?(resource_parent, supported_widget_class)).to be true
      end
    end

    context 'when the widget class is not supported' do
      let(:unsupported_widget_class) { WorkItems::Widgets::EmailParticipants }

      it 'returns false' do
        expect(type.supports_widget?(resource_parent, unsupported_widget_class)).to be false
      end
    end
  end

  describe '#supports_assignee?' do
    let(:type) { build(:work_item_system_defined_type) }
    let(:resource_parent) { build(:project) }

    subject { type.supports_assignee?(resource_parent) }

    context 'when the type includes the Assignees widget' do
      it { is_expected.to be true }
    end

    context 'when the type does not include the Assignees widget' do
      before do
        allow(type).to receive(:widget_classes).with(resource_parent)
          .and_return([::WorkItems::Widgets::Description, ::WorkItems::Widgets::TimeTracking])
      end

      it { is_expected.to be false }
    end
  end

  describe '#supports_time_tracking?' do
    let(:type) { build(:work_item_system_defined_type) }
    let(:resource_parent) { build(:project) }

    subject { type.supports_time_tracking?(resource_parent) }

    context 'when the type includes the TimeTracking widget' do
      it { is_expected.to be true }
    end

    context 'when the type does not include the TimeTracking widget' do
      before do
        allow(type).to receive(:widget_classes).with(resource_parent)
          .and_return([::WorkItems::Widgets::Description, ::WorkItems::Widgets::Assignees])
      end

      it { is_expected.to be false }
    end
  end

  describe 'hierarchy methods' do
    let(:issue_type) { build(:work_item_system_defined_type, :issue) }
    let(:task_type) { build(:work_item_system_defined_type, :task) }

    describe '#allowed_child_types_by_name' do
      it 'returns child types ordered by name' do
        children = issue_type.allowed_child_types_by_name

        expect(children.map(&:id)).to include(task_type.id)
      end

      it 'returns empty relation when no children exist' do
        children = task_type.allowed_child_types_by_name

        expect(children.count).to eq(0)
      end

      it 'orders results by name' do
        # Add multiple children to test ordering
        incident_type = build(:work_item_system_defined_type, :incident)

        children = incident_type.allowed_child_types_by_name
        names = children.map(&:name)

        expect(names).to eq(names.sort)
      end
    end

    describe '#allowed_parent_types_by_name' do
      it 'returns parent types ordered by name' do
        parents = task_type.allowed_parent_types_by_name

        expect(parents.map(&:id)).to include(issue_type.id)
      end

      it 'orders results by name' do
        parents = task_type.allowed_parent_types_by_name
        names = parents.map(&:name)

        expect(names).to eq(names.sort)
      end
    end

    describe '#allowed_child_types' do
      context 'when authorize is false' do
        it 'returns all allowed child types' do
          children = issue_type.allowed_child_types(authorize: false)

          expect(children.map(&:id)).to include(task_type.id)
        end

        it 'does not call authorized_types' do
          expect(issue_type).not_to receive(:authorized_types)

          issue_type.allowed_child_types(authorize: false)
        end
      end

      context 'when authorize is true' do
        let(:project) { build(:project) }
        let(:user) { build(:user) }

        it 'returns authorized child types' do
          children = issue_type.allowed_child_types(
            authorize: true,
            resource_parent: project
          )

          expect(children).to be_present
        end
      end
    end

    describe '#allowed_parent_types' do
      context 'when authorize is false' do
        it 'returns all allowed parent types' do
          parents = task_type.allowed_parent_types(authorize: false)

          expect(parents.map(&:id)).to include(issue_type.id)
        end

        it 'does not call authorized_types' do
          expect(issue_type).not_to receive(:authorized_types)

          issue_type.allowed_parent_types(authorize: false)
        end
      end

      context 'when authorize is true' do
        let(:project) { build(:project) }

        it 'returns authorized parent types' do
          parents = task_type.allowed_parent_types(
            authorize: true,
            resource_parent: project
          )

          expect(parents).to be_present
        end
      end
    end

    describe '#descendant_types' do
      it 'returns all descendant types' do
        descendants = issue_type.descendant_types

        expect(descendants.size).to eq(1)
        expect(descendants.map(&:id)).to include(task_type.id)
      end

      it 'returns empty array when no descendants exist' do
        descendants = task_type.descendant_types

        expect(descendants).to be_empty
      end

      context "with multi-level hierarchy" do
        let(:issue_type) do
          described_class.new(id: 1, name: 'Issue', base_type: 'issue', icon_name: 'issue-type-issue')
        end

        let(:task_type) { described_class.new(id: 5, name: 'Task', base_type: 'task', icon_name: 'issue-type-task') }
        let(:subtask_type) do
          described_class.new(id: 20, name: 'Subtask', base_type: 'subtask', icon_name: 'icon-subtask')
        end

        let(:mock_types) { [issue_type, task_type, subtask_type] }

        before do
          allow(described_class).to receive(:all).and_return(mock_types)
        end

        it 'returns all descendants in a multi-level hierarchy' do
          # Mock a multi-level hierarchy: issue_type -> task_type-> subtask_type
          allow(issue_type).to receive(:allowed_child_types).and_return([task_type])
          allow(task_type).to receive(:allowed_child_types).and_return([subtask_type])

          descendants = issue_type.descendant_types

          # Should include both task and subtask
          expect(descendants).to include(task_type, subtask_type)
          expect(descendants.size).to eq(2)
        end
      end
    end
  end

  describe '#supported_conversion_types' do
    let(:issue_type) { build(:work_item_system_defined_type, :issue) }
    let(:task_type) { build(:work_item_system_defined_type, :task) }
    let(:project) { build(:project) }
    let(:user) { build(:user) }

    it 'excludes the current type' do
      result = issue_type.supported_conversion_types(project, user)

      expect(result.map(&:base_type)).not_to include('issue')
    end

    it 'orders results by name' do
      result = issue_type.supported_conversion_types(project, user)
      names = result.map(&:name)

      expect(names).to eq(names.sort)
    end

    it 'includes task type for issue conversion' do
      result = issue_type.supported_conversion_types(project, user)

      expect(result.map(&:base_type)).to include('task')
    end

    it 'includes incident type for issue conversion' do
      result = issue_type.supported_conversion_types(project, user)

      expect(result.map(&:base_type)).to include('incident')
    end

    it 'includes ticket type for issue conversion' do
      result = issue_type.supported_conversion_types(project, user)

      expect(result.map(&:base_type)).to include('ticket')
    end
  end

  describe 'for configurable methods' do
    let(:type) { build(:work_item_system_defined_type) } # Issue type
    let(:configuration_class) { WorkItems::TypesFramework::SystemDefined::Definitions::Issue }

    before do
      allow(type).to receive(:configuration_class).and_return(configuration_class)
    end

    describe '#supports_roadmap_view?' do
      context 'when configuration_class supports roadmap view' do
        it 'returns true' do
          allow(configuration_class).to receive(:supports_roadmap_view?).and_return(true)

          expect(type.supports_roadmap_view?).to be true
        end
      end

      context 'when configuration_class does not support roadmap view' do
        it 'returns false' do
          allow(configuration_class).to receive(:supports_roadmap_view?).and_return(false)

          expect(type.supports_roadmap_view?).to be false
        end
      end

      context 'when configuration_class does not respond to supports_roadmap_view?' do
        it 'returns false as default' do
          allow(configuration_class).to receive(:supports_roadmap_view?).and_return(nil)

          expect(type.supports_roadmap_view?).to be false
        end
      end
    end

    describe '#use_legacy_view?' do
      context 'when configuration_class uses legacy view' do
        it 'returns true' do
          allow(configuration_class).to receive(:use_legacy_view?).and_return(true)

          expect(type.use_legacy_view?).to be true
        end
      end

      context 'when configuration_class does not use legacy view' do
        it 'returns false' do
          allow(configuration_class).to receive(:use_legacy_view?).and_return(false)

          expect(type.use_legacy_view?).to be false
        end
      end

      context 'when configuration_class does not respond to use_legacy_view?' do
        it 'returns false as default' do
          allow(configuration_class).to receive(:use_legacy_view?).and_return(nil)

          expect(type.use_legacy_view?).to be false
        end
      end
    end

    describe '#can_promote_to_objective?' do
      context 'when configuration_class can promote to objective' do
        it 'returns true' do
          allow(configuration_class).to receive(:can_promote_to_objective?).and_return(true)

          expect(type.can_promote_to_objective?).to be true
        end
      end

      context 'when configuration_class cannot promote to objective' do
        it 'returns false' do
          allow(configuration_class).to receive(:can_promote_to_objective?).and_return(false)

          expect(type.can_promote_to_objective?).to be false
        end
      end

      context 'when configuration_class does not respond to can_promote_to_objective?' do
        it 'returns false as default' do
          allow(configuration_class).to receive(:can_promote_to_objective?).and_return(nil)

          expect(type.can_promote_to_objective?).to be false
        end
      end
    end

    describe '#show_project_selector?' do
      context 'when configuration_class shows project selector' do
        it 'returns true' do
          allow(configuration_class).to receive(:show_project_selector?).and_return(true)

          expect(type.show_project_selector?).to be true
        end
      end

      context 'when configuration_class does not show project selector' do
        it 'returns false' do
          allow(configuration_class).to receive(:show_project_selector?).and_return(false)

          expect(type.show_project_selector?).to be false
        end
      end

      context 'when configuration_class does not respond to show_project_selector?' do
        it 'returns true as default' do
          allow(configuration_class).to receive(:show_project_selector?).and_return(nil)

          expect(type.show_project_selector?).to be true
        end
      end
    end

    describe '#supports_move_action?' do
      context 'when configuration_class supports move action' do
        it 'returns true' do
          allow(configuration_class).to receive(:supports_move_action?).and_return(true)

          expect(type.supports_move_action?).to be true
        end
      end

      context 'when configuration_class does not support move action' do
        it 'returns false' do
          allow(configuration_class).to receive(:supports_move_action?).and_return(false)

          expect(type.supports_move_action?).to be false
        end
      end

      context 'when configuration_class does not respond to supports_move_action?' do
        it 'returns false as default' do
          allow(configuration_class).to receive(:supports_move_action?).and_return(nil)

          expect(type.supports_move_action?).to be false
        end
      end
    end

    describe '#service_desk?' do
      context 'when configuration_class responds to service_desk?' do
        it 'returns true when configuration_class.service_desk? is true' do
          allow(type.configuration_class).to receive(:service_desk?).and_return(true)

          expect(type.service_desk?).to be true
        end

        it 'returns false when configuration_class.service_desk? is false' do
          allow(type.configuration_class).to receive(:service_desk?).and_return(false)

          expect(type.service_desk?).to be false
        end
      end

      context 'when configuration_class does not respond to service_desk?' do
        it 'returns false as default' do
          allow(type.configuration_class).to receive(:try).with(:service_desk?).and_return(nil)

          expect(type.service_desk?).to be false
        end
      end
    end

    describe '#incident_management?' do
      context 'when configuration_class responds to incident_management?' do
        it 'returns true when configuration_class.incident_management? is true' do
          allow(type.configuration_class).to receive(:incident_management?).and_return(true)

          expect(type.incident_management?).to be true
        end

        it 'returns false when configuration_class.incident_management? is false' do
          allow(type.configuration_class).to receive(:incident_management?).and_return(false)

          expect(type.incident_management?).to be false
        end
      end

      context 'when configuration_class does not respond to incident_management?' do
        it 'returns false as default' do
          allow(type.configuration_class).to receive(:try).with(:incident_management?).and_return(nil)

          expect(type.incident_management?).to be false
        end
      end
    end

    describe '#configurable?' do
      context 'when configuration_class responds to configurable?' do
        it 'returns true when configuration_class.configurable? is true' do
          allow(type.configuration_class).to receive(:configurable?).and_return(true)

          expect(type.configurable?).to be true
        end

        it 'returns false when configuration_class.configurable? is explicitly false' do
          allow(type.configuration_class).to receive(:configurable?).and_return(false)

          expect(type.configurable?).to be false
        end
      end

      context 'when configuration_class does not respond to configurable?' do
        it 'returns true as default when value is nil' do
          allow(type.configuration_class).to receive(:try).with(:configurable?).and_return(nil)

          expect(type.configurable?).to be true
        end
      end
    end

    describe '#creatable?' do
      context 'when configuration_class responds to creatable?' do
        it 'returns true when configuration_class.creatable? is true' do
          allow(type.configuration_class).to receive(:creatable?).and_return(true)

          expect(type.creatable?).to be true
        end

        it 'returns false when configuration_class.creatable? is explicitly false' do
          allow(type.configuration_class).to receive(:creatable?).and_return(false)

          expect(type.creatable?).to be false
        end
      end

      context 'when configuration_class does not respond to creatable?' do
        it 'returns true as default when value is nil' do
          allow(type.configuration_class).to receive(:try).with(:creatable?).and_return(nil)

          expect(type.creatable?).to be true
        end
      end
    end

    describe '#visible_in_settings??' do
      context 'when configuration_class responds to visible_in_settings??' do
        it 'returns true when configuration_class.visible_in_settings?? is true' do
          allow(type.configuration_class).to receive(:visible_in_settings?).and_return(true)

          expect(type.visible_in_settings?).to be true
        end

        it 'returns false when configuration_class.visible_in_settings?? is explicitly false' do
          allow(type.configuration_class).to receive(:visible_in_settings?).and_return(false)

          expect(type.visible_in_settings?).to be false
        end
      end

      context 'when configuration_class does not respond to visible_in_settings??' do
        it 'returns true as default when value is nil' do
          allow(type.configuration_class).to receive(:try).with(:visible_in_settings?).and_return(nil)

          expect(type.visible_in_settings?).to be true
        end
      end
    end

    describe '#archived?' do
      context 'when configuration_class responds to archived?' do
        it 'returns true when configuration_class.archived? is true' do
          allow(type.configuration_class).to receive(:archived?).and_return(true)

          expect(type.archived?).to be true
        end

        it 'returns false when configuration_class.archived? is explicitly false' do
          allow(type.configuration_class).to receive(:archived?).and_return(false)

          expect(type.archived?).to be false
        end
      end

      context 'when configuration_class does not respond to archived?' do
        it 'returns false as default when value is nil' do
          allow(type.configuration_class).to receive(:try).with(:archived?).and_return(nil)

          expect(type.archived?).to be false
        end
      end
    end

    describe '#filterable?' do
      context 'when configuration_class responds to filterable?' do
        it 'returns true when configuration_class.filterable? is true' do
          allow(type.configuration_class).to receive(:filterable?).and_return(true)

          expect(type.filterable?).to be true
        end

        it 'returns false when configuration_class.filterable?is explicitly false' do
          allow(type.configuration_class).to receive(:filterable?).and_return(false)

          expect(type.filterable?).to be false
        end
      end

      context 'when configuration_class does not respond to filterable?' do
        it 'returns false as default when value is nil' do
          allow(type.configuration_class).to receive(:try).with(:filterable?).and_return(nil)

          expect(type.filterable?).to be false
        end
      end
    end

    describe '#only_for_group?' do
      context 'when configuration_class responds to only_for_group?' do
        it 'returns true when configuration_class.only_for_group? is true' do
          allow(type.configuration_class).to receive(:only_for_group?).and_return(true)

          expect(type.only_for_group?).to be true
        end

        it 'returns false when configuration_class.only_for_group? is false' do
          allow(type.configuration_class).to receive(:only_for_group?).and_return(false)

          expect(type.only_for_group?).to be false
        end
      end

      context 'when configuration_class does not respond to only_for_group?' do
        it 'returns false as default' do
          allow(type.configuration_class).to receive(:try).with(:only_for_group?).and_return(nil)

          expect(type.only_for_group?).to be false
        end
      end
    end

    describe '#enabled?' do
      it 'returns true' do
        expect(type.enabled?).to be true
      end
    end
  end

  describe '.base_types' do
    it 'includes all types from .all' do
      base_types = described_class.base_types
      all_types = described_class.all

      expect(base_types.values).to match_array(all_types)
    end

    it 'uses base_type as the key' do
      base_types = described_class.base_types

      base_types.each do |key, value|
        expect(value.base_type).to eq(key)
      end
    end
  end

  describe '.find_by_id' do
    it 'finds type by numeric id' do
      type = described_class.find_by_id(1)

      expect(type).to be_present
      expect(type.id).to eq(1)
      expect(type.name).to eq('Issue')
    end

    it 'finds type by string id' do
      type = described_class.find_by_id('5')

      expect(type).to be_present
      expect(type.id).to eq(5)
      expect(type.name).to eq('Task')
    end

    it 'returns nil for non-existent id' do
      expect(described_class.find_by_id(999)).to be_nil
    end

    it 'returns nil for nil id' do
      expect(described_class.find_by_id(nil)).to be_nil
    end
  end

  describe '.with_widget_definition' do
    let(:assignees_widget_type) { :assignees }
    let(:description_widget_type) { :description }
    let(:non_existent_widget_type) { :non_existent_widget }

    it 'returns types that have the specified widget definition' do
      types = described_class.with_widget_definition(assignees_widget_type)

      expect(types).to be_present
      expect(types).to all(be_a(described_class))
    end

    it 'only returns types with the specified widget' do
      types = described_class.with_widget_definition(assignees_widget_type)

      types.each do |type|
        widget_defs = WorkItems::TypesFramework::SystemDefined::WidgetDefinition
          .where(work_item_type_id: type.id, widget_type: assignees_widget_type.to_s)

        expect(widget_defs).to be_present
      end
    end

    it 'returns empty array when no types have the widget' do
      types = described_class.with_widget_definition(non_existent_widget_type)

      expect(types).to be_empty
    end

    it 'accepts string widget type' do
      types = described_class.with_widget_definition('description')

      expect(types).to be_present
    end

    it 'returns different results for different widgets' do
      types_with_assignees = described_class.with_widget_definition(:assignees)
      types_with_description = described_class.with_widget_definition(:description)

      # Both should have results but they might be different sets
      expect(types_with_assignees).to be_present
      expect(types_with_description).to be_present
    end
  end

  describe '#configuration_class' do
    it 'returns the correct configuration class for issue type' do
      issue_type = build(:work_item_system_defined_type, :issue)

      expect(issue_type.configuration_class).to eq(
        WorkItems::TypesFramework::SystemDefined::Definitions::Issue
      )
    end

    it 'returns the correct configuration class for incident type' do
      incident_type = build(:work_item_system_defined_type, :incident)

      expect(incident_type.configuration_class).to eq(
        WorkItems::TypesFramework::SystemDefined::Definitions::Incident
      )
    end

    it 'returns the correct configuration class for task type' do
      task_type = build(:work_item_system_defined_type, :task)

      expect(task_type.configuration_class).to eq(
        WorkItems::TypesFramework::SystemDefined::Definitions::Task
      )
    end

    it 'returns the correct configuration class for ticket type' do
      ticket_type = build(:work_item_system_defined_type, :ticket)

      expect(ticket_type.configuration_class).to eq(
        WorkItems::TypesFramework::SystemDefined::Definitions::Ticket
      )
    end

    it 'camelizes the base_type name' do
      issue_type = build(:work_item_system_defined_type, :issue)

      expect(issue_type.base_type).to eq('issue')
      expect(issue_type.configuration_class.name).to include('Issue')
    end
  end

  describe '#license_name' do
    let(:type) { build(:work_item_system_defined_type) }

    context 'when configuration_class defines a license_name' do
      it 'returns the license name' do
        allow(type.configuration_class).to receive(:license_name).and_return('premium')

        expect(type.license_name).to eq('premium')
      end
    end

    context 'when configuration_class does not define a license_name' do
      it 'returns nil' do
        allow(type.configuration_class).to receive(:license_name).and_return(nil)

        expect(type.license_name).to be_nil
      end
    end

    context 'when configuration_class does not respond to license_name' do
      it 'returns nil' do
        allow(type.configuration_class).to receive(:try).with(:license_name).and_return(nil)

        expect(type.license_name).to be_nil
      end
    end
  end

  describe '#licensed?' do
    let(:type) { build(:work_item_system_defined_type) }

    context 'when license_name is present' do
      it 'returns true' do
        allow(type).to receive(:license_name).and_return('premium')

        expect(type.licensed?).to be true
      end
    end

    context 'when license_name is nil' do
      it 'returns false' do
        allow(type).to receive(:license_name).and_return(nil)

        expect(type.licensed?).to be false
      end
    end

    context 'when license_name is an empty string' do
      it 'returns false' do
        allow(type).to receive(:license_name).and_return('')

        expect(type.licensed?).to be false
      end
    end
  end
end
