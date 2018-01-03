require 'spec_helper'

describe Admin::AbuseReportsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let!(:abuse_report) { create(:abuse_report) }
  let!(:abuse_report_with_short_message) { create(:abuse_report, message: 'SHORT MESSAGE') }
  let!(:abuse_report_with_long_message) { create(:abuse_report, message: "LONG MESSAGE\n" * 50) }

  render_views

  before(:all) do
    clean_frontend_fixtures('abuse_reports/')
  end

  before do
    sign_in(admin)
  end

  it 'abuse_reports/abuse_reports_list.html.raw' do |example|
    get :index

    expect(response).to be_success
    store_frontend_fixture(response, example.description)
  end
end
