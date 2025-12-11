# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::SystemDefined::WidgetDefinition, feature_category: :team_planning do
  describe 'attributes' do
    it 'has attributes' do
      definition = build(:work_item_system_defined_widget_definition, widget_type: 'assignees')
      expect(definition.widget_type).to eq('assignees')
      expect(definition.name).to eq("Assignees")
      expect(definition.work_item_type_id).to eq(1) # Issue type
    end
  end

  describe 'associations' do
    it 'belongs to work_item_type through fixed_items' do
      type = build(:work_item_system_defined_type, :task)
      definition = build(:work_item_system_defined_widget_definition, widget_type: 'assignees',
        work_item_type_id: type.id)

      expect(definition.work_item_type).to eq(type)
    end
  end

  describe 'auto_generate_ids!' do
    it 'generates IDs automatically for fixed items' do
      items = described_class.all

      # IDs should be present
      expect(items).to all(have_attributes(id: be_present))

      # IDs should be integers
      expect(items.map(&:id)).to all(be_a(Integer))
    end
  end

  describe '.fixed_items' do
    let(:fixed_items) { described_class.fixed_items }
    let(:issue_type) { build(:work_item_system_defined_type, :issue) }
    let(:task_type) { build(:work_item_system_defined_type, :task) }
    let(:incident_type) { build(:work_item_system_defined_type, :incident) }

    it 'generates widget definitions for all work item types' do
      work_item_type_ids = WorkItems::SystemDefined::Type.all.map(&:id)
      definition_type_ids = fixed_items.pluck(:work_item_type_id).uniq

      expect(definition_type_ids).to match_array(work_item_type_ids)
    end

    it 'includes all required attributes for each widget definition' do
      expect(fixed_items).to all(include(:widget_type, :work_item_type_id, :name))
    end

    it 'sets widget_type from configuration class .widgets method' do
      issue_widgets = fixed_items.select { |item| item[:work_item_type_id] == issue_type.id }

      expected_widget_types = WorkItems::SystemDefined::Types::Issue.widgets
      actual_widget_types = issue_widgets.pluck(:widget_type)

      expect(actual_widget_types).to match_array(expected_widget_types)
    end

    it 'sets work_item_type_id correctly for each widget' do
      task_widgets = fixed_items.select { |item| item[:work_item_type_id] == task_type.id }

      expect(task_widgets).to all(include(work_item_type_id: task_type.id))
    end

    it 'sets widget_options from configuration class .widget_options method' do
      definition = fixed_items.find do |item|
        item[:work_item_type_id] == issue_type.id && item[:widget_type] == 'weight'
      end

      expect(definition[:widget_options]).to eq(WorkItems::SystemDefined::Types::Issue.widget_options[:weight])
    end

    it 'sets name as humanized version of widget_type' do
      sample_definition = fixed_items.first

      expected_name = sample_definition[:widget_type].to_s.humanize
      expect(sample_definition[:name]).to eq(expected_name)
    end

    context 'with widget_options handling' do
      it 'includes widget_options when defined in configuration' do
        # weight widget, have a widget options
        definition = fixed_items.find do |item|
          item[:work_item_type_id] == issue_type.id && item[:widget_type] == 'weight'
        end

        expect(definition[:widget_options]).to be_a(Hash)
      end

      it 'excludes widget_options key when not defined (due to compact)' do
        # description widget, does not have a widget options
        definition = fixed_items.find do |item|
          item[:work_item_type_id] == issue_type.id && item[:widget_type] == 'description'
        end

        expect(definition.key?(:widget_options)).to be(false)
      end
    end

    context 'for integration with Type configuration classes' do
      let(:config_class) { issue_type.configuration_class }

      it 'correctly reads .widget_options method from configuration class' do
        expect(config_class.widget_options).to be_a(Hash)
      end
    end

    context 'for name generation' do
      it 'humanizes single word widget types' do
        definition = fixed_items.find do |item|
          item[:work_item_type_id] == issue_type.id && item[:widget_type] == 'assignees'
        end

        expect(definition[:name]).to eq('Assignees')
      end

      it 'humanizes multi-word widget types with underscores' do
        definition = fixed_items.find do |item|
          item[:work_item_type_id] == issue_type.id && item[:widget_type] == 'start_and_due_date'
        end

        expect(definition[:name]).to eq('Start and due date')
      end

      it 'humanizes widget types with acronyms' do
        definition = fixed_items.find do |item|
          item[:work_item_type_id] == issue_type.id && item[:widget_type] == 'crm_contacts'
        end

        expect(definition[:name]).to eq('Crm contacts')
      end
    end
  end

  describe '.widget_types' do
    let(:widget_types) { described_class.widget_types }

    it 'returns an array of strings' do
      expect(widget_types).to be_an(Array)
      expect(widget_types).to all(be_a(String))
    end

    it 'returns all expected widget types' do
      expected_types = %w[
        assignees
        award_emoji
        crm_contacts
        current_user_todos
        description
        designs
        development
        email_participants
        error_tracking
        hierarchy
        labels
        linked_items
        linked_resources
        milestone
        notes
        notifications
        participants
        start_and_due_date
        time_tracking
      ]

      # we use include instead of match_array as it also addes the EE widgets
      expect(widget_types).to include(*expected_types)
    end
  end

  describe '.available_widgets' do
    let(:available_widgets) { described_class.available_widgets }

    it 'returns an array of widget classes' do
      expect(available_widgets).to be_an(Array)
      expect(available_widgets).to all(be_a(Class))
    end

    it 'returns all expected widget classes' do
      expected_widgets = [
        WorkItems::Widgets::Assignees,
        WorkItems::Widgets::AwardEmoji,
        WorkItems::Widgets::CrmContacts,
        WorkItems::Widgets::CurrentUserTodos,
        WorkItems::Widgets::Description,
        WorkItems::Widgets::Designs,
        WorkItems::Widgets::Development,
        WorkItems::Widgets::EmailParticipants,
        WorkItems::Widgets::ErrorTracking,
        WorkItems::Widgets::Hierarchy,
        WorkItems::Widgets::Labels,
        WorkItems::Widgets::LinkedItems,
        WorkItems::Widgets::LinkedResources,
        WorkItems::Widgets::Milestone,
        WorkItems::Widgets::Notes,
        WorkItems::Widgets::Notifications,
        WorkItems::Widgets::Participants,
        WorkItems::Widgets::StartAndDueDate,
        WorkItems::Widgets::TimeTracking
      ]

      # we use include instead of match_array as it also adds the EE widgets when running in EE
      expect(available_widgets).to include(*expected_widgets)
    end

    it 'uses filter_map to remove nil values' do
      # Verify that nil values are filtered out
      expect(available_widgets).not_to include(nil)
    end

    it 'returns unique widget classes' do
      expect(available_widgets.uniq.size).to eq(available_widgets.size)
    end
  end

  describe '#widget_class' do
    context 'with valid widget types' do
      it 'returns widget class for all types' do
        expected_types = {
          assignees: WorkItems::Widgets::Assignees,
          award_emoji: WorkItems::Widgets::AwardEmoji,
          crm_contacts: WorkItems::Widgets::CrmContacts,
          current_user_todos: WorkItems::Widgets::CurrentUserTodos,
          description: WorkItems::Widgets::Description,
          designs: WorkItems::Widgets::Designs,
          development: WorkItems::Widgets::Development,
          email_participants: WorkItems::Widgets::EmailParticipants,
          error_tracking: WorkItems::Widgets::ErrorTracking,
          hierarchy: WorkItems::Widgets::Hierarchy,
          labels: WorkItems::Widgets::Labels,
          linked_items: WorkItems::Widgets::LinkedItems,
          linked_resources: WorkItems::Widgets::LinkedResources,
          milestone: WorkItems::Widgets::Milestone,
          notes: WorkItems::Widgets::Notes,
          notifications: WorkItems::Widgets::Notifications,
          participants: WorkItems::Widgets::Participants,
          start_and_due_date: WorkItems::Widgets::StartAndDueDate,
          time_tracking: WorkItems::Widgets::TimeTracking
        }

        expected_types.each do |type, klass|
          definition = build(:work_item_system_defined_widget_definition, widget_type: type.to_s)
          expect(definition.widget_class).to eq(klass)
        end
      end
    end

    context 'with invalid widget types' do
      it 'returns nil for non-existent widget type' do
        definition = described_class.new(widget_type: :nonexistent_widget)

        expect(definition.widget_class).to be_nil
      end

      it 'returns nil when widget_type is nil' do
        definition = described_class.new(widget_type: nil)

        expect(definition.widget_class).to be_nil
      end
    end

    context 'for const_get behavior' do
      let(:definition) { build(:work_item_system_defined_widget_definition, widget_type: 'assignees') }

      it 'uses const_get with inherit=false' do
        expect(WorkItems::Widgets).to receive(:const_get).with('Assignees', false).and_call_original
        definition.widget_class
      end

      it 'does not inherit constants from parent modules' do
        # Verify the second argument is false (no inheritance)
        allow(WorkItems::Widgets).to receive(:const_get).and_call_original
        definition.widget_class

        expect(WorkItems::Widgets).to have_received(:const_get).with(anything, false)
      end
    end
  end

  describe '#build_widget' do
    let(:work_item) { build(:work_item) }
    let(:definition) { build(:work_item_system_defined_widget_definition, widget_type: 'assignees') }

    it 'creates a widget instance with all the correct attributes' do
      widget = definition.build_widget(work_item)

      expect(widget).to be_a(WorkItems::Widgets::Assignees)
      expect(widget.work_item).to eq(work_item)
      expect(widget.instance_variable_get(:@widget_definition)).to eq(definition)
    end

    context 'with different widget types' do
      it 'builds Description widget' do
        definition = build(:work_item_system_defined_widget_definition, :description)
        widget = definition.build_widget(work_item)

        expect(widget).to be_a(WorkItems::Widgets::Description)
      end
    end

    context 'when widget_class is nil' do
      it 'raises an error when trying to build widget with invalid type' do
        definition = described_class.new(widget_type: 'nonexistent', work_item_type_id: 1)

        expect { definition.build_widget(work_item) }.to raise_error(NoMethodError)
      end
    end
  end

  describe '#licensed?' do
    let(:widget_definition) { build(:work_item_system_defined_widget_definition) }

    subject(:licensed?) { widget_definition.licensed?(resource_parent) }

    context "when resource_parent id nil" do
      let(:resource_parent) { nil }

      it { is_expected.to be true }
    end

    context "when resource_parent exists and it is a project" do
      let(:resource_parent) { build_stubbed(:project) }

      it { is_expected.to be true }
    end

    context "when resource_parent exists and it is a group" do
      let(:resource_parent) { build_stubbed(:group) }

      it { is_expected.to be true }
    end
  end
end
