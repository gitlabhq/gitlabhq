# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Widgets::Milestone, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project1) { create(:project, group: group) }
  let_it_be(:project2) { create(:project, group: group) }
  let_it_be(:milestone1) { create(:milestone, group: group, title: 'sample milestone') }
  let_it_be_with_reload(:work_item) { create(:work_item, milestone: milestone1, project: project1) }
  let_it_be_with_reload(:target_work_item) { create(:work_item, project: project2) }

  let(:params) { {} }

  subject(:callback) do
    described_class.new(
      work_item: work_item, target_work_item: target_work_item, current_user: current_user, params: params
    )
  end

  context 'when target work item does not have milestone widget' do
    before do
      target_work_item.reload
      allow(target_work_item).to receive(:get_widget).with(:milestone).and_return(false)
    end

    context 'with before_create callback' do
      it 'does not copy milestone' do
        expect(callback).not_to receive(:matching_milestone)

        callback.before_create

        expect(target_work_item.milestone).to be_nil
      end
    end

    context 'with after_save_commit callback' do
      it 'does not create milestone resource event' do
        expect(callback).not_to receive(:handle_changed_milestone_system_notes)

        callback.before_create
        expect { callback.after_save_commit }.not_to change { ResourceMilestoneEvent.count }
      end
    end
  end

  context 'when target work item has milestone widget' do
    before do
      allow(target_work_item).to receive(:get_widget).with(:milestone).and_return(true)
    end

    context 'when source and target work items are within same hierarchy' do
      context 'with before_create callback' do
        it 'copies milestone from work_item to target_work_item' do
          expect(callback).to receive(:matching_milestone).and_call_original

          callback.before_create

          expect(target_work_item.milestone).to eq(milestone1)
        end
      end

      context 'with after_save_commit callback' do
        it 'does not create milestone resource event' do
          expect(callback).to receive(:handle_changed_milestone_system_notes).and_call_original

          callback.before_create
          expect { callback.after_save_commit }.not_to change { ResourceMilestoneEvent.count }
        end
      end
    end

    context 'when source and target work items are in different hierarchies' do
      let_it_be(:target_group) { create(:group) }
      let_it_be(:target_project) { create(:project, group: target_group) }
      let_it_be(:milestone2) { create(:milestone, group: target_group, title: 'sample one milestone') }
      let_it_be_with_reload(:target_work_item) { create(:work_item, project: target_project) }

      context 'when no milestone matches by title in new hierarchy' do
        context 'with before_create callback' do
          it 'does not copy milestone' do
            expect(callback).to receive(:matching_milestone).and_call_original

            callback.before_create

            expect(target_work_item.milestone).to be_nil
            expect(target_work_item.milestone_id).not_to eq(work_item.milestone_id)
          end
        end

        context 'with after_save_commit callback' do
          it 'creates milestone resource event' do
            expect(callback).to receive(:handle_changed_milestone_system_notes).and_call_original

            callback.before_create
            expect { callback.after_save_commit }.to change { ResourceMilestoneEvent.count }.by(1)
          end
        end
      end

      context 'when milestone matches by title in new hierarchy' do
        let_it_be(:milestone3) { create(:milestone, group: target_group, title: 'sample milestone') }

        context 'with before_create callback' do
          it 'copies milestone from work_item to target_work_item' do
            expect(callback).to receive(:matching_milestone).and_call_original

            callback.before_create

            expect(target_work_item.milestone).to eq(milestone3)
            expect(target_work_item.milestone_id).not_to eq(work_item.milestone_id)
          end
        end

        context 'with after_save_commit callback' do
          it 'creates milestone resource event' do
            expect(callback).to receive(:handle_changed_milestone_system_notes).and_call_original

            callback.before_create
            expect { callback.after_save_commit }.to change { ResourceMilestoneEvent.count }.by(1)
          end
        end
      end
    end
  end

  describe '#post_move_cleanup' do
    it 'is defined and can be called' do
      expect { callback.post_move_cleanup }.not_to raise_error
    end

    it 'removes original work item milestone' do
      callback.post_move_cleanup

      expect(work_item.milestone).to be_nil
    end
  end
end
