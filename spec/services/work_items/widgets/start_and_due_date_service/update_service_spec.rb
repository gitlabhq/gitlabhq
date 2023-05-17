# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::StartAndDueDateService::UpdateService, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:work_item) { create(:work_item, project: project) }

  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::StartAndDueDate) } }

  describe '#before_update_callback' do
    let(:start_date) { Date.today }
    let(:due_date) { 1.week.from_now.to_date }
    let(:service) { described_class.new(widget: widget, current_user: user) }

    subject(:update_params) { service.before_update_callback(params: params) }

    context 'when start and due date params are present' do
      let(:params) { { start_date: Date.today, due_date: 1.week.from_now.to_date } }

      it 'correctly sets date values' do
        expect do
          update_params
        end.to change(work_item, :start_date).from(nil).to(start_date).and(
          change(work_item, :due_date).from(nil).to(due_date)
        )
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
          end.to change(work_item, :start_date).from(start_date).to(nil).and(
            not_change(work_item, :due_date).from(due_date)
          )
        end
      end
    end

    context 'when widget does not exist in new type' do
      let(:params) { {} }

      before do
        allow(service).to receive(:new_type_excludes_widget?).and_return(true)
        work_item.update!(start_date: start_date, due_date: due_date)
      end

      it 'sets both dates to null' do
        expect do
          update_params
        end.to change(work_item, :start_date).from(start_date).to(nil).and(
          change(work_item, :due_date).from(due_date).to(nil)
        )
      end
    end
  end
end
