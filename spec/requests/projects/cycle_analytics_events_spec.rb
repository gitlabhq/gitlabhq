require 'spec_helper'

describe 'cycle analytics events' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  describe 'GET /:namespace/:project/cycle_analytics/events/issues' do
    before do
      project.team << [user, :developer]

      login_as(user)
    end

    it 'lists the issue events' do
      get namespace_project_cycle_analytics_issues_path(project.namespace, project, format: :json)

      expect(json_response).to eq ([])
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
