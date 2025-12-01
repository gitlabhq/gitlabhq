# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::SystemDefined::Type, feature_category: :team_planning do
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

  describe 'hierarchy methods' do
    let(:issue_type) { described_class.find_by_type(:issue) }
    let(:task_type) { described_class.find_by_type(:task) }

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
        incident_type = described_class.find_by_type(:incident)

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

        it 'calls authorized_types with correct parameters' do
          expect(issue_type).to receive(:authorized_types)
            .with(anything, project, :child)
            .and_call_original

          issue_type.allowed_child_types(authorize: true, resource_parent: project)
        end

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

        it 'calls authorized_types with correct parameters' do
          expect(task_type).to receive(:authorized_types)
            .with(anything, project, :parent)
            .and_call_original

          task_type.allowed_parent_types(authorize: true, resource_parent: project)
        end

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
    let(:issue_type) { described_class.find_by_type(:issue) }
    let(:task_type) { described_class.find_by_type(:task) }
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
end
