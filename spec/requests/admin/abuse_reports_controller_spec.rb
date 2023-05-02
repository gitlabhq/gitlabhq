# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AbuseReportsController, type: :request, feature_category: :insider_threat do
  include AdminModeHelper

  let_it_be(:admin) { create(:admin) }

  before do
    enable_admin_mode!(admin)
    sign_in(admin)
  end

  describe 'GET #index' do
    let!(:open_report) { create(:abuse_report) }
    let!(:closed_report) { create(:abuse_report, :closed) }

    it 'returns open reports by default' do
      get admin_abuse_reports_path

      expect(assigns(:abuse_reports).count).to eq 1
      expect(assigns(:abuse_reports).first.open?).to eq true
    end

    it 'returns reports by specified status' do
      get admin_abuse_reports_path, params: { status: 'closed' }

      expect(assigns(:abuse_reports).count).to eq 1
      expect(assigns(:abuse_reports).first.closed?).to eq true
    end

    context 'when abuse_reports_list flag is disabled' do
      before do
        stub_feature_flags(abuse_reports_list: false)
      end

      it 'returns all reports by default' do
        get admin_abuse_reports_path

        expect(assigns(:abuse_reports).count).to eq 2
      end
    end
  end

  describe 'GET #show' do
    let!(:report) { create(:abuse_report) }

    it 'returns the requested report' do
      get admin_abuse_report_path(report)

      expect(assigns(:abuse_report)).to eq report
    end
  end
end
