# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::AdjournedDeletable, feature_category: :groups_and_projects do
  let(:model) do
    Class.new do
      include Namespaces::AdjournedDeletable
    end
  end

  let(:record) { model.new }

  describe '#self_deletion_in_progress?' do
    it 'raises NotImplementedError by default' do
      expect { record.self_deletion_in_progress? }.to raise_error(NotImplementedError)
    end

    context 'when implemented' do
      before do
        model.send(:define_method, :self_deletion_in_progress?) do
          true
        end
      end

      it 'returns the implemented value' do
        expect(record.self_deletion_in_progress?).to be_truthy
      end
    end
  end

  describe '#self_deletion_scheduled_deletion_created_on', :freeze_time do
    context 'when record responds to :marked_for_deletion_on' do
      it 'returns marked_for_deletion_on' do
        allow(record).to receive(:marked_for_deletion_on).and_return(Time.current)

        expect(record.self_deletion_scheduled_deletion_created_on).to eq(Time.current)
      end
    end

    context 'when record does not respond to :marked_for_deletion_on' do
      it 'returns nil' do
        expect(record.self_deletion_scheduled_deletion_created_on).to be_nil
      end
    end
  end

  describe '#self_deletion_scheduled?' do
    context 'when self_deletion_scheduled_deletion_created_on is nil' do
      it 'returns false' do
        expect(record.self_deletion_scheduled?).to be(false)
      end
    end

    context 'when self_deletion_scheduled_deletion_created_on is present' do
      before do
        allow(record).to receive(:self_deletion_scheduled_deletion_created_on).and_return(Time.current)
      end

      it 'returns true' do
        expect(record.self_deletion_scheduled?).to be(true)
      end
    end
  end

  describe '#ancestor_scheduled_for_deletion?' do
    context 'when ancestors_scheduled_for_deletion is empty' do
      it 'returns false' do
        expect(record.ancestor_scheduled_for_deletion?).to be(false)
      end
    end

    context 'when ancestors_scheduled_for_deletion is present' do
      before do
        allow(record).to receive(:ancestors_scheduled_for_deletion).and_return([1])
      end

      it 'returns true' do
        expect(record.ancestor_scheduled_for_deletion?).to be(true)
      end
    end
  end

  describe '#first_scheduled_for_deletion_in_hierarchy_chain' do
    it 'returns nil' do
      expect(record.first_scheduled_for_deletion_in_hierarchy_chain).to be_nil
    end
  end

  describe '#deletion_in_progress_or_scheduled_in_hierarchy_chain?' do
    context 'when #self_deletion_in_progress? is false' do
      before do
        allow(record).to receive(:self_deletion_in_progress?).and_return(false)
      end

      it 'returns false' do
        expect(record.deletion_in_progress_or_scheduled_in_hierarchy_chain?).to be_falsy
      end

      context 'when #scheduled_for_deletion_in_hierarchy_chain? is true' do
        before do
          allow(record).to receive(:scheduled_for_deletion_in_hierarchy_chain?).and_return(true)
        end

        it 'returns true' do
          expect(record.deletion_in_progress_or_scheduled_in_hierarchy_chain?).to be_truthy
        end
      end
    end

    context 'when #self_deletion_in_progress? is true' do
      before do
        allow(record).to receive(:self_deletion_in_progress?).and_return(true)
      end

      it 'returns true' do
        expect(record.deletion_in_progress_or_scheduled_in_hierarchy_chain?).to be_truthy
      end
    end
  end

  describe Namespace do
    describe '#self_deletion_in_progress?' do
      context 'when deleted_at is nil' do
        let_it_be(:namespace) { create(:namespace) }

        it 'returns false' do
          expect(namespace.self_deletion_in_progress?).to be_falsy
        end
      end

      context 'when deleted_at is not nil' do
        let_it_be(:namespace) { create(:namespace) { |n| n.deleted_at = Time.current } }

        it 'returns true' do
          expect(namespace.self_deletion_in_progress?).to be_truthy
        end
      end
    end

    describe '#first_scheduled_for_deletion_in_hierarchy_chain' do
      let_it_be_with_reload(:group) { create(:group) }

      context 'when the group has been marked for deletion' do
        before do
          create(:group_deletion_schedule, group: group, marked_for_deletion_on: 1.day.ago)
        end

        it 'returns the group' do
          expect(group.first_scheduled_for_deletion_in_hierarchy_chain).to eq(group)
        end
      end

      context 'when the parent group has been marked for deletion' do
        let(:parent_group) { create(:group_with_deletion_schedule, marked_for_deletion_on: 1.day.ago) }
        let(:group) { create(:group, parent: parent_group) }

        it 'returns the parent group' do
          expect(group.first_scheduled_for_deletion_in_hierarchy_chain).to eq(parent_group)
        end
      end

      context 'when parent group has not been marked for deletion' do
        let(:parent_group) { create(:group) }
        let(:group) { create(:group, parent: parent_group) }

        it 'returns nil' do
          expect(group.first_scheduled_for_deletion_in_hierarchy_chain).to be_nil
        end
      end

      describe 'ordering of parents marked for deletion' do
        let(:group_a) { create(:group_with_deletion_schedule, marked_for_deletion_on: 1.day.ago) }
        let(:subgroup_a) { create(:group_with_deletion_schedule, marked_for_deletion_on: 1.day.ago, parent: group_a) }
        let(:group) { create(:group, parent: subgroup_a) }

        it 'returns the ancestors marked for deletion, ordered from closest to farthest' do
          expect(group.first_scheduled_for_deletion_in_hierarchy_chain).to eq(subgroup_a)
        end
      end
    end
  end

  describe Project do
    describe '#self_deletion_in_progress?' do
      context 'when pending_delete is false' do
        let_it_be(:project) { create(:project, pending_delete: false) }

        it 'returns false' do
          expect(project.self_deletion_in_progress?).to be_falsy
        end
      end

      context 'when pending_delete is true' do
        let_it_be(:project) { create(:project, pending_delete: true) }

        it 'returns true' do
          expect(project.self_deletion_in_progress?).to be_truthy
        end
      end
    end

    describe '#first_scheduled_for_deletion_in_hierarchy_chain' do
      context 'when the project has been marked for deletion' do
        let_it_be(:project) { create(:project, :aimed_for_deletion) }

        it 'returns the project' do
          expect(project.first_scheduled_for_deletion_in_hierarchy_chain).to eq(project)
        end
      end

      context 'when the parent group has been marked for deletion' do
        let_it_be(:parent_group) do
          create(:group_with_deletion_schedule, marked_for_deletion_on: 1.day.ago)
        end

        let_it_be(:project) { create(:project, namespace: parent_group) }

        it 'returns the parent group' do
          expect(project.first_scheduled_for_deletion_in_hierarchy_chain).to eq(parent_group)
        end
      end

      context 'when parent group has not been marked for deletion' do
        let_it_be(:parent_group) { create(:group) }
        let_it_be(:project) { create(:project, namespace: parent_group) }

        it 'returns nil' do
          expect(project.first_scheduled_for_deletion_in_hierarchy_chain).to be_nil
        end
      end

      describe 'ordering of parents marked for deletion' do
        let_it_be(:group_a) { create(:group_with_deletion_schedule, marked_for_deletion_on: 1.day.ago) }
        let_it_be(:subgroup_a) do
          create(:group_with_deletion_schedule, marked_for_deletion_on: 1.day.ago, parent: group_a)
        end

        let_it_be(:project) { create(:project, namespace: subgroup_a) }

        it 'returns the ancestors marked for deletion, ordered from closest to farthest' do
          expect(project.first_scheduled_for_deletion_in_hierarchy_chain).to eq(subgroup_a)
        end
      end
    end
  end
end
