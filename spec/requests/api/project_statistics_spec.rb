# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectStatistics do
  let(:maintainer) { create(:user) }
  let(:public_project) { create(:project, :public) }

  before do
    public_project.add_maintainer(maintainer)
  end

  describe 'GET /projects/:id/statistics' do
    let!(:fetch_statistics1) { create(:project_daily_statistic, project: public_project, fetch_count: 30, date: 29.days.ago) }
    let!(:fetch_statistics2) { create(:project_daily_statistic, project: public_project, fetch_count: 4, date: 3.days.ago) }
    let!(:fetch_statistics3) { create(:project_daily_statistic, project: public_project, fetch_count: 3, date: 2.days.ago) }
    let!(:fetch_statistics4) { create(:project_daily_statistic, project: public_project, fetch_count: 2, date: 1.day.ago) }
    let!(:fetch_statistics5) { create(:project_daily_statistic, project: public_project, fetch_count: 1, date: Date.today) }
    let!(:fetch_statistics_other_project) { create(:project_daily_statistic, project: create(:project), fetch_count: 29, date: 29.days.ago) }

    it 'returns the fetch statistics of the last 30 days' do
      get api("/projects/#{public_project.id}/statistics", maintainer)

      expect(response).to have_gitlab_http_status(:ok)
      fetches = json_response['fetches']
      expect(fetches['total']).to eq(40)
      expect(fetches['days'].length).to eq(5)
      expect(fetches['days'].first).to eq({ 'count' => fetch_statistics5.fetch_count, 'date' => fetch_statistics5.date.to_s })
      expect(fetches['days'].last).to eq({ 'count' => fetch_statistics1.fetch_count, 'date' => fetch_statistics1.date.to_s })
    end

    it 'excludes the fetch statistics older than 30 days' do
      create(:project_daily_statistic, fetch_count: 31, project: public_project, date: 30.days.ago)

      get api("/projects/#{public_project.id}/statistics", maintainer)

      expect(response).to have_gitlab_http_status(:ok)
      fetches = json_response['fetches']
      expect(fetches['total']).to eq(40)
      expect(fetches['days'].length).to eq(5)
      expect(fetches['days'].last).to eq({ 'count' => fetch_statistics1.fetch_count, 'date' => fetch_statistics1.date.to_s })
    end

    it 'responds with 403 when the user is not a maintainer of the repository' do
      developer = create(:user)
      public_project.add_developer(developer)

      get api("/projects/#{public_project.id}/statistics", developer)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden')
    end
  end
end
