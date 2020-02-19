# frozen_string_literal: true

require 'spec_helper'

describe Groups::MilestonesController do
  context 'N+1 DB queries' do
    let(:user) { create(:user) }
    let!(:public_group) { create(:group, :public) }

    let!(:public_project_with_private_issues_and_mrs) do
      create(:project, :public, :issues_private, :merge_requests_private, group: public_group)
    end
    let!(:private_milestone) { create(:milestone, project: public_project_with_private_issues_and_mrs, title: 'project milestone') }

    it 'avoids N+1 database queries' do
      public_project = create(:project, :public, :merge_requests_enabled, :issues_enabled, group: public_group)
      create(:milestone, project: public_project)

      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { get "/groups/#{public_group.to_param}/-/milestones.json" }.count

      projects = create_list(:project, 2, :public, :merge_requests_enabled, :issues_enabled, group: public_group)
      projects.each do |project|
        create(:milestone, project: project)
      end

      expect { get "/groups/#{public_group.to_param}/-/milestones.json" }.not_to exceed_all_query_limit(control_count)
      expect(response).to have_gitlab_http_status(:ok)
      milestones = json_response

      expect(milestones.count).to eq(3)
      expect(milestones.map {|x| x['title']}).not_to include(private_milestone.title)
    end
  end
end
