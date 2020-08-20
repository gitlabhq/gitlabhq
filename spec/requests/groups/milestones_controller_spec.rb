# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::MilestonesController do
  context 'N+1 DB queries' do
    let(:user) { create(:user) }
    let!(:public_group) { create(:group, :public) }

    let!(:public_project_with_private_issues_and_mrs) do
      create(:project, :public, :issues_private, :merge_requests_private, group: public_group)
    end

    let!(:private_milestone) { create(:milestone, project: public_project_with_private_issues_and_mrs, title: 'project milestone') }

    describe 'GET #index' do
      it 'avoids N+1 database queries' do
        public_project = create(:project, :public, :merge_requests_enabled, :issues_enabled, group: public_group)
        create(:milestone, project: public_project)

        control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { get group_milestones_path(public_group, format: :json) }.count

        projects = create_list(:project, 2, :public, :merge_requests_enabled, :issues_enabled, group: public_group)
        projects.each do |project|
          create(:milestone, project: project)
        end

        expect { get group_milestones_path(public_group, format: :json) }.not_to exceed_all_query_limit(control_count)
        expect(response).to have_gitlab_http_status(:ok)
        milestones = json_response

        expect(milestones.count).to eq(3)
        expect(milestones.map {|x| x['title']}).not_to include(private_milestone.title)
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
  end
end
