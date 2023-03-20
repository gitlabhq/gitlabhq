# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::ChangeMilestoneService, feature_category: :team_planning do
  let_it_be(:timebox) { create(:milestone) }

  let(:created_at_time) { Time.utc(2019, 12, 30) }
  let(:add_timebox_args) { { old_milestone: nil } }
  let(:remove_timebox_args) { { old_milestone: timebox } }

  [:issue, :merge_request].each do |issuable|
    it_behaves_like 'timebox(milestone or iteration) resource events creator', ResourceMilestoneEvent do
      let_it_be(:resource) { create(issuable) } # rubocop:disable Rails/SaveBang
    end
  end

  describe 'events tracking' do
    let_it_be(:user) { create(:user) }

    let(:resource) { create(resource_type, milestone: timebox, project: timebox.project) }

    subject(:service_instance) { described_class.new(resource, user, old_milestone: nil) }

    context 'when the resource is a work item' do
      let(:resource_type) { :work_item }

      it 'tracks work item usage data counters' do
        expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter)
          .to receive(:track_work_item_milestone_changed_action)
          .with(author: user)

        service_instance.execute
      end
    end

    context 'when the resource is not a work item' do
      let(:resource_type) { :issue }

      it 'does not track work item usage data counters' do
        expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter)
          .not_to receive(:track_work_item_milestone_changed_action)

        service_instance.execute
      end
    end
  end
end
