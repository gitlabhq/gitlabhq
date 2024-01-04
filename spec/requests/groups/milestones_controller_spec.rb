# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::MilestonesController, feature_category: :team_planning do
  context 'N+1 DB queries' do
    let_it_be(:user) { create(:user) }
    let_it_be(:public_group) { create(:group, :public) }

    let!(:public_project_with_private_issues_and_mrs) do
      create(:project, :public, :issues_private, :merge_requests_private, group: public_group)
    end

    let!(:private_milestone) { create(:milestone, project: public_project_with_private_issues_and_mrs, title: 'project milestone') }

    describe 'GET #index' do
      it 'avoids N+1 database queries' do
        public_project = create(:project, :public, :merge_requests_enabled, :issues_enabled, group: public_group)
        create(:milestone, project: public_project)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          get group_milestones_path(public_group, format: :json)
        end

        projects = create_list(:project, 2, :public, :merge_requests_enabled, :issues_enabled, group: public_group)
        projects.each do |project|
          create(:milestone, project: project)
        end

        expect { get group_milestones_path(public_group, format: :json) }.not_to exceed_all_query_limit(control)
        expect(response).to have_gitlab_http_status(:ok)
        milestones = json_response

        expect(milestones.count).to eq(3)
        expect(milestones.map { |x| x['title'] }).not_to include(private_milestone.title)
      end
    end

    describe 'GET #show' do
      let(:milestone) { create(:milestone, group: public_group) }
      let(:show_path) { group_milestone_path(public_group, milestone) }

      it 'avoids N+1 database queries' do
        projects = create_list(:project, 3, :public, :merge_requests_enabled, :issues_enabled, group: public_group)
        projects.each do |project|
          create_list(:issue, 2, milestone: milestone, project: project)
        end
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { get show_path }

        projects = create_list(:project, 3, :public, :merge_requests_enabled, :issues_enabled, group: public_group)
        projects.each do |project|
          create_list(:issue, 2, milestone: milestone, project: project)
        end

        expect { get show_path }.not_to exceed_all_query_limit(control)
      end
    end

    describe 'GET #merge_requests' do
      let(:milestone) { create(:milestone, group: public_group) }
      let(:project) { create(:project, :public, :merge_requests_enabled, :issues_enabled, group: public_group) }
      let!(:merge_request) { create(:merge_request, milestone: milestone, source_project: project) }

      def perform_request
        get merge_requests_group_milestone_path(public_group, milestone, format: :json)
      end

      it 'avoids N+1 database queries' do
        perform_request # warm up the cache

        control = ActiveRecord::QueryRecorder.new { perform_request }

        create(:merge_request, milestone: milestone, source_project: project, source_branch: 'fix')

        expect { perform_request }.not_to exceed_query_limit(control)
      end
    end
  end
end
