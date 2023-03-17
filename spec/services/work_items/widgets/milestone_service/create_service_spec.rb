# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::MilestoneService::CreateService, feature_category: :portfolio_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:project_milestone) { create(:milestone, project: project) }
  let_it_be(:group_milestone) { create(:milestone, group: group) }
  let_it_be(:guest) { create(:user) }

  let(:current_user) { guest }
  let(:work_item) { build(:work_item, project: project, updated_at: 1.day.ago) }
  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::Milestone) } }
  let(:service) { described_class.new(widget: widget, current_user: current_user) }

  before do
    project.add_guest(guest)
  end

  describe '#before_create_callback' do
    it_behaves_like "setting work item's milestone" do
      subject(:execute_callback) do
        service.before_create_callback(params: params)
      end
    end
  end
end
