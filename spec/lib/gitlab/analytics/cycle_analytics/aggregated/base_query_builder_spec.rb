# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::Aggregated::BaseQueryBuilder do
  let_it_be(:group) { create(:group, :with_organization) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:user_1) { create(:user) }

  let_it_be(:label_1) { create(:label, project: project) }
  let_it_be(:label_2) { create(:label, project: project) }

  let_it_be(:issue_1) { create(:issue, project: project, author: project.creator, labels: [label_1, label_2]) }
  let_it_be(:issue_2) { create(:issue, project: project, milestone: milestone, assignees: [user_1]) }
  let_it_be(:issue_3) { create(:issue, project: project) }
  let_it_be(:issue_outside_project) { create(:issue) }

  let_it_be(:stage) do
    create(
      :cycle_analytics_stage,
      project: project,
      start_event_identifier: :issue_created,
      end_event_identifier: :issue_deployed_to_production
    )
  end

  let_it_be(:stage_event_1) do
    create(
      :cycle_analytics_issue_stage_event,
      stage_event_hash_id: stage.stage_event_hash_id,
      group_id: group.id,
      project_id: project.id,
      issue_id: issue_1.id,
      author_id: project.creator.id,
      milestone_id: nil,
      state_id: issue_1.state_id,
      end_event_timestamp: 8.months.ago
    )
  end

  let_it_be(:stage_event_2) do
    create(
      :cycle_analytics_issue_stage_event,
      stage_event_hash_id: stage.stage_event_hash_id,
      group_id: group.id,
      project_id: project.id,
      issue_id: issue_2.id,
      author_id: nil,
      milestone_id: milestone.id,
      state_id: issue_2.state_id
    )
  end

  let_it_be(:stage_event_3) do
    create(
      :cycle_analytics_issue_stage_event,
      stage_event_hash_id: stage.stage_event_hash_id,
      group_id: group.id,
      project_id: project.id,
      issue_id: issue_3.id,
      author_id: nil,
      milestone_id: milestone.id,
      state_id: issue_3.state_id,
      start_event_timestamp: 8.months.ago,
      end_event_timestamp: nil
    )
  end

  let(:params) do
    {
      from: 1.year.ago.to_date,
      to: Date.today
    }
  end

  subject(:issue_ids) { described_class.new(stage: stage, params: params).build.pluck(:issue_id) }

  it 'scopes the query for the given project' do
    expect(issue_ids).to match_array([issue_1.id, issue_2.id])
    expect(issue_ids).not_to include([issue_outside_project.id])
  end

  describe 'author_username param' do
    it 'returns stage events associated with the given author' do
      params[:author_username] = project.creator.username

      expect(issue_ids).to eq([issue_1.id])
    end

    it 'returns empty result when unknown author is given' do
      params[:author_username] = 'no one'

      expect(issue_ids).to be_empty
    end
  end

  describe 'milestone_title param' do
    it 'returns stage events associated with the milestone' do
      params[:milestone_title] = milestone.title

      expect(issue_ids).to eq([issue_2.id])
    end

    it 'returns empty result when unknown milestone is given' do
      params[:milestone_title] = 'unknown milestone'

      expect(issue_ids).to be_empty
    end
  end

  describe 'label_name param' do
    it 'returns stage events associated with multiple labels' do
      params[:label_name] = [label_1.name, label_2.name]

      expect(issue_ids).to eq([issue_1.id])
    end

    it 'does not include records with partial label match' do
      params[:label_name] = [label_1.name, 'other label']

      expect(issue_ids).to be_empty
    end
  end

  describe 'assignee_username param' do
    it 'returns stage events associated assignee' do
      params[:assignee_username] = [user_1.username]

      expect(issue_ids).to eq([issue_2.id])
    end
  end

  describe 'timestamp filtering' do
    before do
      params[:from] = 1.year.ago
      params[:to] = 6.months.ago
    end

    it 'filters by the end event time range' do
      expect(issue_ids).to eq([issue_1.id])
    end

    context 'when in_progress items are requested' do
      before do
        params[:end_event_filter] = :in_progress
      end

      it 'filters by the start event time range' do
        expect(issue_ids).to eq([issue_3.id])
      end
    end
  end
end
