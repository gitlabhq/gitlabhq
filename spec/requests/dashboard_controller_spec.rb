# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DashboardController, feature_category: :authentication_and_authorization do
  context 'token authentication' do
    it_behaves_like 'authenticates sessionless user for the request spec', 'issues atom', public_resource: false do
      let(:url) { issues_dashboard_url(:atom, assignee_username: user.username) }
    end

    it_behaves_like 'authenticates sessionless user for the request spec', 'issues_calendar ics', public_resource: false do
      let(:url) { issues_dashboard_url(:ics, assignee_username: user.username) }
    end
  end
end
