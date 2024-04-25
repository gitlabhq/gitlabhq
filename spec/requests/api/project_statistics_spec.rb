# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectStatistics, feature_category: :source_code_management do
  let_it_be(:reporter) { create(:user) }
  let_it_be(:public_project) { create(:project, :public, reporters: reporter) }

  describe 'GET /projects/:id/statistics' do
    let_it_be(:fetch_statistics1) { create(:project_daily_statistic, project: public_project, fetch_count: 30, date: 29.days.ago) }
    let_it_be(:fetch_statistics2) { create(:project_daily_statistic, project: public_project, fetch_count: 4, date: 3.days.ago) }
    let_it_be(:fetch_statistics3) { create(:project_daily_statistic, project: public_project, fetch_count: 3, date: 2.days.ago) }
    let_it_be(:fetch_statistics4) { create(:project_daily_statistic, project: public_project, fetch_count: 2, date: 1.day.ago) }
    let_it_be(:fetch_statistics5) { create(:project_daily_statistic, project: public_project, fetch_count: 1, date: Date.today) }
    let_it_be(:fetch_statistics_other_project) { create(:project_daily_statistic, project: create(:project), fetch_count: 29, date: 29.days.ago) }

    it 'returns the fetch statistics of the last 30 days' do
      get api("/projects/#{public_project.id}/statistics", reporter)

      expect(response).to have_gitlab_http_status(:ok)
      fetches = json_response['fetches']
      expect(fetches['total']).to eq(40)
      expect(fetches['days'].length).to eq(5)
      expect(fetches['days'].first).to eq({ 'count' => fetch_statistics5.fetch_count, 'date' => fetch_statistics5.date.to_s })
      expect(fetches['days'].last).to eq({ 'count' => fetch_statistics1.fetch_count, 'date' => fetch_statistics1.date.to_s })
    end

    it 'excludes the fetch statistics older than 30 days' do
      create(:project_daily_statistic, fetch_count: 31, project: public_project, date: 30.days.ago)

      get api("/projects/#{public_project.id}/statistics", reporter)

      expect(response).to have_gitlab_http_status(:ok)
      fetches = json_response['fetches']
      expect(fetches['total']).to eq(40)
      expect(fetches['days'].length).to eq(5)
      expect(fetches['days'].last).to eq({ 'count' => fetch_statistics1.fetch_count, 'date' => fetch_statistics1.date.to_s })
    end

    it 'responds with 403 when the user is not a reporter of the repository' do
      guest = create(:user)
      public_project.add_guest(guest)

      get api("/projects/#{public_project.id}/statistics", guest)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden')
    end
  end
end
