# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Callbacks::StartAndDueDate, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, reporter_of: project) }
  let_it_be_with_reload(:work_item) { create(:work_item, project: project) }

  let(:widget) { work_item.get_widget(:start_and_due_date) }

  subject(:service) { described_class.new(issuable: work_item, current_user: user, params: params) }

  shared_examples "when user does not have permissions to update the dates" do
    let_it_be(:user) { create(:user) }

    specify do
      expect { update_dates }
        .to not_change { work_item.dates_source&.start_date }
        .and not_change { work_item.start_date }
        .and not_change { work_item.dates_source&.due_date }
        .and not_change { work_item.due_date }
    end
  end

  shared_examples "updating work item's dates_source" do
    let(:start_date) { Date.today }
    let(:due_date) { 1.week.from_now.to_date }

    context "when start and due date params are present" do
      let(:params) { { start_date: start_date, due_date: due_date } }

      it_behaves_like "when user does not have permissions to update the dates"

      it "correctly sets date values" do
        expect { update_dates }
          .to change { work_item.start_date }.from(nil).to(start_date)
          .and change { work_item.due_date }.from(nil).to(due_date)
          .and change { work_item.dates_source&.start_date }.from(nil).to(start_date)
          .and change { work_item.dates_source&.start_date_fixed }.from(nil).to(start_date)
          .and change { work_item.dates_source&.start_date_is_fixed }.from(nil).to(true)
          .and change { work_item.dates_source&.due_date }.from(nil).to(due_date)
          .and change { work_item.dates_source&.due_date_fixed }.from(nil).to(due_date)
          .and change { work_item.dates_source&.due_date_is_fixed }.from(nil).to(true)
      end
    end

    context "when date params are not present" do
      let(:params) { {} }

      it "does not change work item date values" do
        expect { update_dates }
          .to not_change { work_item.dates_source&.start_date }.from(nil)
          .and not_change { work_item.start_date }.from(nil)
          .and not_change { work_item.dates_source&.due_date }.from(nil)
          .and not_change { work_item.due_date }.from(nil)
      end
    end

    context "when work item had both date values already set" do
      before do
        work_item.dates_source = WorkItems::DatesSource.new(start_date: start_date, due_date: due_date)
      end

      context "and date params are not present" do
        let(:params) { {} }

        it "does not change work item date values" do
          expect { update_dates }
            .to not_change { work_item.dates_source.start_date }
            .and not_change { work_item.start_date }
            .and not_change { work_item.dates_source.due_date }
            .and not_change { work_item.due_date }
        end
      end

      context "when unsetting the start_date" do
        let(:params) { { start_date: nil } }

        it 'sets only one date to null' do
          expect { update_dates }
            .to change { work_item.dates_source&.start_date }.from(start_date).to(nil)
            .and change { work_item.start_date }.from(start_date).to(nil)
            .and change { work_item.dates_source&.start_date_is_fixed }.from(false).to(true)
            .and change { work_item.dates_source&.due_date_is_fixed }.from(false).to(true)
            .and not_change { work_item.dates_source&.due_date }.from(due_date)
            .and not_change { work_item.due_date }.from(due_date)
        end
      end

      context "when unsetting the due_date" do
        let(:params) { { due_date: nil } }

        it 'sets only one date to null' do
          expect { update_dates }
            .to change { work_item.dates_source&.due_date }.from(due_date).to(nil)
            .and change { work_item.due_date }.from(due_date).to(nil)
            .and change { work_item.dates_source&.start_date_is_fixed }.from(false).to(true)
            .and not_change { work_item.dates_source&.start_date }.from(start_date)
            .and not_change { work_item.start_date }.from(start_date)
            .and change { work_item.dates_source&.due_date_is_fixed }.from(false).to(true)
        end
      end

      context "when widget does not exist in new type" do
        let(:params) { {} }

        before do
          allow(service).to receive(:excluded_in_new_type?).and_return(true)
        end

        it_behaves_like "when user does not have permissions to update the dates"

        it "sets both dates to null" do
          expect { update_dates }
            .to change { work_item.dates_source&.start_date }.from(start_date).to(nil)
            .and change { work_item.start_date }.from(start_date).to(nil)
            .and change { work_item.dates_source&.start_date_is_fixed }.from(false).to(true)
            .and change { work_item.dates_source&.due_date }.from(due_date).to(nil)
            .and change { work_item.due_date }.from(due_date).to(nil)
            .and change { work_item.dates_source&.due_date_is_fixed }.from(false).to(true)
        end
      end
    end
  end

  describe "#before_create" do
    let(:update_dates) { service.before_create }

    it_behaves_like "updating work item's dates_source"
  end

  describe "#before_update" do
    let(:update_dates) { service.before_update }

    it_behaves_like "updating work item's dates_source"
  end
end
