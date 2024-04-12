# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Callbacks::StartAndDueDate, feature_category: :portfolio_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, reporter_of: project) }
  let_it_be_with_reload(:work_item) { create(:work_item, project: project) }

  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Callbacks::StartAndDueDate) } }

  describe '#before_update_callback' do
    let(:start_date) { Date.today }
    let(:due_date) { 1.week.from_now.to_date }
    let(:service) { described_class.new(issuable: work_item, current_user: user, params: params) }

    subject(:update_params) { service.before_update }

    context 'when start and due date params are present' do
      let(:params) { { start_date: Date.today, due_date: 1.week.from_now.to_date } }

      it 'correctly sets date values' do
        expect do
          update_params
        end.to change { work_item.start_date }.from(nil).to(start_date).and(
          change { work_item.due_date }.from(nil).to(due_date)
        )
      end

      context "and user doesn't have permissions to update start and due date" do
        let_it_be(:user) { create(:user) }

        it 'removes start and due date params params' do
          expect(update_params).to be_nil
        end
      end
    end

    context 'when date params are not present' do
      let(:params) { {} }

      it 'does not change work item date values' do
        expect do
          update_params
        end.to not_change(work_item, :start_date).from(nil).and(
          not_change(work_item, :due_date).from(nil)
        )
      end
    end

    context 'when work item had both date values already set' do
      before do
        work_item.update!(start_date: start_date, due_date: due_date)
      end

      context 'when one of the two params is null' do
        let(:params) { { start_date: nil } }

        it 'sets only one date to null' do
          expect do
            update_params
          end.to change { work_item.start_date }.from(start_date).to(nil).and(
            not_change(work_item, :due_date).from(due_date)
          )
        end
      end
    end

    context 'when widget does not exist in new type' do
      let(:params) { {} }

      before do
        allow(service).to receive(:excluded_in_new_type?).and_return(true)
        work_item.update!(start_date: start_date, due_date: due_date)
      end

      it 'sets both dates to null' do
        expect do
          update_params
        end.to change { work_item.start_date }.from(start_date).to(nil).and(
          change { work_item.due_date }.from(due_date).to(nil)
        )
      end
    end
  end
end
