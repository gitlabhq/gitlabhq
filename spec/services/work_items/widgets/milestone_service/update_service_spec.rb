# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::MilestoneService::UpdateService do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:project_milestone) { create(:milestone, project: project) }
  let_it_be(:group_milestone) { create(:milestone, group: group) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:guest) { create(:user) }

  let(:work_item) { create(:work_item, project: project, updated_at: 1.day.ago) }
  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::Milestone) } }
  let(:service) { described_class.new(widget: widget, current_user: current_user) }

  before do
    project.add_reporter(reporter)
    project.add_guest(guest)
  end

  describe '#before_update_callback' do
    context 'when current user is not allowed to set work item metadata' do
      let(:current_user) { guest }
      let(:params) { { milestone_id: group_milestone.id } }

      it "does not set the work item's milestone" do
        expect { service.before_update_callback(params: params) }
          .to not_change(work_item, :milestone)
      end
    end

    context "when current user is allowed to set work item metadata" do
      let(:current_user) { reporter }

      it_behaves_like "setting work item's milestone" do
        subject(:execute_callback) do
          service.before_update_callback(params: params)
        end
      end

      context 'when unsetting a milestone' do
        let(:params) { { milestone_id: nil } }

        before do
          work_item.update!(milestone: project_milestone)
        end

        it "sets the work item's milestone" do
          expect { service.before_update_callback(params: params) }
            .to change(work_item, :milestone)
            .from(project_milestone)
            .to(nil)
        end
      end
    end
  end
end
