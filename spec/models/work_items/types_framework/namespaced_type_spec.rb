# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::TypesFramework::NamespacedType, feature_category: :team_planning do
  let(:system_type) { build(:work_item_system_defined_type, :issue) }

  describe '#class' do
    it 'returns the wrapped type class for system-defined types' do
      namespaced = described_class.new(system_type)

      expect(namespaced.class).to eq(WorkItems::TypesFramework::SystemDefined::Type)
    end
  end

  describe '#is_a?' do
    it 'returns true for the wrapped type class' do
      namespaced = described_class.new(system_type)

      expect(namespaced.is_a?(WorkItems::TypesFramework::SystemDefined::Type)).to be(true)
    end

    it 'returns true for SimpleDelegator' do
      namespaced = described_class.new(system_type)

      expect(namespaced.is_a?(SimpleDelegator)).to be(true)
    end
  end

  describe '#kind_of?' do
    it 'is aliased to is_a?' do
      namespaced = described_class.new(system_type)

      expect(namespaced.is_a?(WorkItems::TypesFramework::SystemDefined::Type)).to be(true)
    end
  end

  describe '#instance_of?' do
    it 'returns true for the wrapped type class' do
      namespaced = described_class.new(system_type)

      expect(namespaced.instance_of?(WorkItems::TypesFramework::SystemDefined::Type)).to be(true)
    end

    it 'returns false for NamespacedType' do
      namespaced = described_class.new(system_type)

      expect(namespaced.instance_of?(described_class)).to be(false)
    end
  end

  describe '#enabled?' do
    it 'returns true when enabled, not archived, and visible in context' do
      allow(system_type).to receive_messages(archived?: false, only_for_group?: false)
      namespaced = described_class.new(system_type, enabled: true, is_a_group: false)

      expect(namespaced.enabled?).to be(true)
    end

    it 'returns false when the visibility toggle is off' do
      allow(system_type).to receive_messages(archived?: false, only_for_group?: false)
      namespaced = described_class.new(system_type, enabled: false, is_a_group: false)

      expect(namespaced.enabled?).to be(false)
    end

    it 'returns false when the type is archived' do
      allow(system_type).to receive_messages(archived?: true, only_for_group?: false)
      namespaced = described_class.new(system_type, enabled: true, is_a_group: false)

      expect(namespaced.enabled?).to be(false)
    end

    it 'returns false for a group-only type in a non-group namespace' do
      allow(system_type).to receive_messages(archived?: false, only_for_group?: true)
      namespaced = described_class.new(system_type, enabled: true, is_a_group: false)

      expect(namespaced.enabled?).to be(false)
    end

    it 'returns false for a non-group type in a group namespace' do
      allow(system_type).to receive_messages(archived?: false, only_for_group?: false)
      namespaced = described_class.new(system_type, enabled: true, is_a_group: true)

      expect(namespaced.enabled?).to be(false)
    end
  end

  describe '#filterable_list_view?' do
    context 'when is_a_group is true' do
      it 'delegates to the wrapped type' do
        allow(system_type).to receive_messages(archived?: false, only_for_group?: true, filterable_list_view?: true)
        namespaced = described_class.new(system_type, is_a_group: true)

        expect(namespaced.filterable_list_view?).to be(true)
      end

      it 'returns false when the type is archived' do
        allow(system_type).to receive_messages(archived?: true, only_for_group?: true, filterable_list_view?: true)
        namespaced = described_class.new(system_type, is_a_group: true)

        expect(namespaced.filterable_list_view?).to be(false)
      end

      it 'remains filterable when disabled at group level' do
        allow(system_type).to receive_messages(archived?: false, only_for_group?: true, filterable_list_view?: true)
        namespaced = described_class.new(system_type, enabled: false, is_a_group: true)

        expect(namespaced.filterable_list_view?).to be(true)
      end
    end

    context 'when is_a_group is false' do
      it 'returns false when type is only_for_group' do
        allow(system_type).to receive_messages(archived?: false, only_for_group?: true, filterable_list_view?: true)
        namespaced = described_class.new(system_type, is_a_group: false)

        expect(namespaced.filterable_list_view?).to be(false)
      end

      it 'returns true when type is not only_for_group and filterable_list_view' do
        allow(system_type).to receive_messages(archived?: false, only_for_group?: false, filterable_list_view?: true)
        namespaced = described_class.new(system_type, is_a_group: false)

        expect(namespaced.filterable_list_view?).to be(true)
      end

      it 'returns false when the type is archived' do
        allow(system_type).to receive_messages(archived?: true, only_for_group?: false, filterable_list_view?: true)
        namespaced = described_class.new(system_type, is_a_group: false)

        expect(namespaced.filterable_list_view?).to be(false)
      end

      it 'returns false when the type is disabled at project level' do
        allow(system_type).to receive_messages(archived?: false, only_for_group?: false, filterable_list_view?: true)
        namespaced = described_class.new(system_type, enabled: false, is_a_group: false)

        expect(namespaced.filterable_list_view?).to be(false)
      end
    end
  end

  describe '#filterable_board_view?' do
    context 'when type is task and tasks_on_boards is true' do
      it 'returns true' do
        task_type = build(:work_item_system_defined_type, :task)
        allow(task_type).to receive(:archived?).and_return(false)
        namespaced = described_class.new(task_type, tasks_on_boards: true)

        expect(namespaced.filterable_board_view?).to be(true)
      end
    end

    context 'when type is not task' do
      it 'delegates to the wrapped type' do
        allow(system_type).to receive_messages(archived?: false, filterable_board_view?: false)
        namespaced = described_class.new(system_type, tasks_on_boards: true)

        expect(namespaced.filterable_board_view?).to be(false)
      end
    end

    context 'when tasks_on_boards is false' do
      it 'delegates to the wrapped type for task types' do
        task_type = build(:work_item_system_defined_type, :task)
        allow(task_type).to receive(:archived?).and_return(false)
        namespaced = described_class.new(task_type, tasks_on_boards: false)

        expect(namespaced.filterable_board_view?).to be(false)
      end
    end

    context 'when the type is archived' do
      it 'returns false even when tasks_on_boards is true' do
        task_type = build(:work_item_system_defined_type, :task)
        allow(task_type).to receive(:archived?).and_return(true)
        namespaced = described_class.new(task_type, tasks_on_boards: true)

        expect(namespaced.filterable_board_view?).to be(false)
      end

      it 'returns false for non-task types regardless of underlying configuration' do
        allow(system_type).to receive_messages(archived?: true, filterable_board_view?: true)
        namespaced = described_class.new(system_type, is_a_group: true)

        expect(namespaced.filterable_board_view?).to be(false)
      end
    end

    context 'when the type is disabled at project level' do
      it 'returns false' do
        allow(system_type).to receive_messages(archived?: false, only_for_group?: false, filterable_board_view?: true)
        namespaced = described_class.new(system_type, enabled: false, is_a_group: false)

        expect(namespaced.filterable_board_view?).to be(false)
      end
    end

    context 'when the type is disabled at group level' do
      it 'remains filterable' do
        allow(system_type).to receive_messages(archived?: false, only_for_group?: true, filterable_board_view?: true)
        namespaced = described_class.new(system_type, enabled: false, is_a_group: true)

        expect(namespaced.filterable_board_view?).to be(true)
      end
    end
  end

  describe '#can_user_create_items?' do
    context 'when all conditions are met' do
      it 'returns true for non-group context with non-group-only type' do
        allow(system_type).to receive_messages(archived?: false, creatable?: true, only_for_group?: false)
        namespaced = described_class.new(system_type, enabled: true, is_a_group: false)

        expect(namespaced.can_user_create_items?).to be(true)
      end

      it 'returns true for group context with group-only type' do
        allow(system_type).to receive_messages(archived?: false, creatable?: true, only_for_group?: true)
        namespaced = described_class.new(system_type, enabled: true, is_a_group: true)

        expect(namespaced.can_user_create_items?).to be(true)
      end
    end

    context 'when not enabled' do
      it 'returns false' do
        allow(system_type).to receive_messages(archived?: false, creatable?: true, only_for_group?: false)
        namespaced = described_class.new(system_type, enabled: false)

        expect(namespaced.can_user_create_items?).to be(false)
      end
    end

    context 'when archived' do
      it 'returns false' do
        allow(system_type).to receive_messages(archived?: true, creatable?: true, only_for_group?: false)
        namespaced = described_class.new(system_type, enabled: true)

        expect(namespaced.can_user_create_items?).to be(false)
      end
    end

    context 'when not creatable' do
      it 'returns false' do
        allow(system_type).to receive_messages(archived?: false, creatable?: false, only_for_group?: false)
        namespaced = described_class.new(system_type, enabled: true)

        expect(namespaced.can_user_create_items?).to be(false)
      end
    end

    context 'when not visible in context' do
      it 'returns false for group-only type in non-group context' do
        allow(system_type).to receive_messages(archived?: false, creatable?: true, only_for_group?: true)
        namespaced = described_class.new(system_type, enabled: true, is_a_group: false)

        expect(namespaced.can_user_create_items?).to be(false)
      end

      it 'returns false for non-group-only type in group context' do
        allow(system_type).to receive_messages(archived?: false, creatable?: true, only_for_group?: false)
        namespaced = described_class.new(system_type, enabled: true, is_a_group: true)

        expect(namespaced.can_user_create_items?).to be(false)
      end
    end
  end

  describe 'delegation' do
    it 'delegates method calls to the wrapped type' do
      namespaced = described_class.new(system_type)

      expect(namespaced.name).to eq(system_type.name)
      expect(namespaced.id).to eq(system_type.id)
      expect(namespaced.base_type).to eq(system_type.base_type)
    end
  end
end
