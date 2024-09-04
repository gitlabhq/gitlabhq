# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::Callbacks::TimeTracking, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:reporter) do
    create(:user, reporter_of: group)
  end

  let_it_be(:guest) do
    create(:user, guest_of: group)
  end

  let(:current_user) { reporter }
  let(:non_string_params) do
    {
      time_estimate: 12.hours.to_i,
      spend_time: {
        duration: 2.hours.to_i,
        user_id: current_user.id,
        spent_at: Date.today
      }
    }
  end

  let(:string_params) do
    {
      time_estimate: "12h",
      timelog: {
        time_spent: "2h",
        summary: "some summary"
      }
    }
  end

  let(:callback) { described_class.new(issuable: issuable, current_user: current_user, params: params) }

  describe '#after_initialize' do
    shared_examples 'raises an Error' do
      it { expect { subject }.to raise_error(::Issuable::Callbacks::Base::Error, message) }
    end

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

        context 'with non string params' do
          let(:params) { non_string_params }

          it_behaves_like 'sets work item time tracking data'
        end

        context 'with string params' do
          let(:params) { string_params }

          it_behaves_like 'sets work item time tracking data'
        end

        context 'when time tracking param is not present' do
          let(:params) { {} }

          it_behaves_like 'does not set work item time tracking data'
        end

        context 'when widget does not exist in new type' do
          let(:params) { non_string_params }

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

        context 'with non string params' do
          let(:params) { non_string_params }

          it_behaves_like 'sets work item time tracking data'
        end

        context 'with string params' do
          let(:params) { string_params }

          it_behaves_like 'sets work item time tracking data'
        end

        context 'when resetting time spent' do
          let(:params) do
            {
              timelog: {
                time_spent: ":reset",
                summary: "remove spent data"
              }
            }
          end

          it 'resets timelogs' do
            callback.after_initialize

            # latest timelog entry is not persisted yet so we cannot use total_time_spent
            expect(issuable.timelogs.sum(&:time_spent)).to eq(0)
          end
        end

        context 'when time tracking param is not present' do
          let(:params) { {} }

          it_behaves_like 'does not set work item time tracking data'
        end

        context 'when widget does not exist in new type' do
          let(:params) { string_params }

          before do
            allow(callback).to receive(:excluded_in_new_type?).and_return(true)
          end

          it_behaves_like 'does not set work item time tracking data'
        end
      end
    end

    context 'with invalid data' do
      let_it_be(:issuable) { create(:work_item, :task, project: project, time_estimate: 2.hours.to_i) }

      subject(:after_initialize) { callback.after_initialize }

      context 'when time_estimate is invalid' do
        let(:params) { { time_estimate: "12abc" } }

        it_behaves_like 'raises an Error' do
          let(:message) { 'Time estimate must be formatted correctly. For example: 1h 30m.' }
        end
      end

      context 'when time_spent is invalid' do
        let(:params) { { timelog: { time_spent: "2abc" } } }

        it_behaves_like 'raises an Error' do
          let(:message) { 'Time spent must be formatted correctly. For example: 1h 30m.' }
        end
      end
    end
  end
end
