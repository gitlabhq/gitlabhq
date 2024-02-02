# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Callbacks::TimeTracking, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:reporter) do
    create(:user).tap { |u| group.add_reporter(u) }
  end

  let_it_be(:guest) do
    create(:user).tap { |u| group.add_guest(u) }
  end

  let(:current_user) { reporter }
  let(:params) do
    {
      time_estimate: 12.hours.to_i,
      spend_time: {
        duration: 2.hours.to_i,
        user_id: current_user.id,
        spent_at: Date.today
      }
    }
  end

  let(:callback) { described_class.new(issuable: issuable, current_user: current_user, params: params) }

  describe '#after_initialize' do
    shared_examples 'sets work item time tracking data' do
      it 'correctly sets time tracking data', :aggregate_failures do
        callback.after_initialize

        expect(issuable.time_spent).to eq(2.hours.to_i)
        expect(issuable.time_estimate).to eq(12.hours.to_i)
        expect(issuable.timelogs.last.time_spent).to eq(2.hours.to_i)
      end
    end

    shared_examples 'does not set work item time tracking data' do
      it 'does not change work item time tracking data', :aggregate_failures do
        callback.after_initialize

        if issuable.persisted?
          expect(issuable.time_estimate).to eq(2.hours.to_i)
          expect(issuable.total_time_spent).to eq(3.hours.to_i)
          expect(issuable.timelogs.last.time_spent).to eq(3.hours.to_i)
        else
          expect(issuable.time_estimate).to eq(0)
          expect(issuable.time_spent).to eq(nil)
          expect(issuable.timelogs).to be_empty
        end
      end
    end

    context 'when at project level' do
      let(:issuable) { project_work_item }

      context 'and work item is not persisted' do
        let(:project_work_item) { build(:work_item, :incident, project: project) }

        it_behaves_like 'sets work item time tracking data'

        context 'when time tracking param is not present' do
          let(:params) { {} }

          it_behaves_like 'does not set work item time tracking data'
        end

        context 'when widget does not exist in new type' do
          before do
            allow(callback).to receive(:excluded_in_new_type?).and_return(true)
          end

          it_behaves_like 'does not set work item time tracking data'
        end
      end

      context 'and work item is persisted' do
        let_it_be_with_reload(:project_work_item) do
          create(:work_item, :task, project: project, time_estimate: 2.hours.to_i)
        end

        let_it_be(:timelog) { create(:timelog, issue: project_work_item, time_spent: 3.hours.to_i) }

        it_behaves_like 'sets work item time tracking data'

        context 'when time tracking param is not present' do
          let(:params) { {} }

          it_behaves_like 'does not set work item time tracking data'
        end

        context 'when widget does not exist in new type' do
          before do
            allow(callback).to receive(:excluded_in_new_type?).and_return(true)
          end

          it_behaves_like 'does not set work item time tracking data'
        end
      end
    end

    context 'when at group level' do
      let(:issuable) { group_work_item }

      context 'and work item is not persisted' do
        let(:group_work_item) { build(:work_item, :task, :group_level, namespace: group) }

        it_behaves_like 'sets work item time tracking data'

        context 'when time tracking param is not present' do
          let(:params) { {} }

          it_behaves_like 'does not set work item time tracking data'
        end
      end

      context 'and work item is persisted' do
        let_it_be_with_reload(:group_work_item) do
          create(:work_item, :task, :group_level, namespace: group, time_estimate: 2.hours.to_i)
        end

        let_it_be(:timelog) { create(:timelog, issue: group_work_item, time_spent: 3.hours.to_i) }

        it_behaves_like 'sets work item time tracking data'
      end
    end
  end
end
