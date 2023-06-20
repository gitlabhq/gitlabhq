# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AbuseReportsController, feature_category: :insider_threat do
  let(:reporter) { create(:user) }
  let(:user)     { create(:user) }
  let(:abuse_category) { 'spam' }

  let(:attrs) do
    attributes_for(:abuse_report) do |hash|
      hash[:user_id] = user.id
      hash[:category] = abuse_category
      hash[:screenshot] = fixture_file_upload('spec/fixtures/dk.png')
    end
  end

  before do
    sign_in(reporter)
  end

  describe 'POST add_category', :aggregate_failures do
    subject(:request) { post add_category_abuse_reports_path, params: request_params }

    context 'when user is reported for abuse' do
      let(:ref_url) { 'http://example.com' }
      let(:request_params) do
        { user_id: user.id, abuse_report: { category: abuse_category, reported_from_url: ref_url } }
      end

      it 'renders new template' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:new)
      end

      it 'sets the instance variables' do
        subject

        expect(assigns(:abuse_report)).to be_kind_of(AbuseReport)
        expect(assigns(:abuse_report)).to have_attributes(
          user_id: user.id,
          category: abuse_category,
          reported_from_url: ref_url
        )
      end

      it 'tracks the snowplow event' do
        subject

        expect_snowplow_event(
          category: 'ReportAbuse',
          action: 'select_abuse_category',
          property: abuse_category,
          user: user
        )
      end
    end

    context 'when abuse_report is missing in params' do
      let(:request_params) { { user_id: user.id } }

      it 'raises an error' do
        expect { subject }.to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'when user_id is missing in params' do
      let(:request_params) { { abuse_report: { category: abuse_category } } }

      it 'redirects the reporter to root_path' do
        subject

        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq(_('Cannot create the abuse report. The user has been deleted.'))
      end
    end

    context 'when the user has already been deleted' do
      let(:request_params) { { user_id: user.id, abuse_report: { category: abuse_category } } }

      it 'redirects the reporter to root_path' do
        user.destroy!

        subject

        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq(_('Cannot create the abuse report. The user has been deleted.'))
      end
    end

    context 'when the user has already been banned' do
      let(:request_params) { { user_id: user.id, abuse_report: { category: abuse_category } } }

      it 'redirects the reporter to the user\'s profile' do
        user.ban

        subject

        expect(response).to redirect_to user
        expect(flash[:alert]).to eq(_('Cannot create the abuse report. This user has been banned.'))
      end
    end
  end

  describe 'POST create' do
    context 'with valid attributes' do
      it 'saves the abuse report' do
        expect do
          post abuse_reports_path(abuse_report: attrs)
        end.to change { AbuseReport.count }.by(1)
      end

      it 'calls notify' do
        expect_next_instance_of(AbuseReport) do |instance|
          expect(instance).to receive(:notify)
        end

        post abuse_reports_path(abuse_report: attrs)
      end

      it 'redirects back to root' do
        post abuse_reports_path(abuse_report: attrs)

        expect(response).to redirect_to root_path
      end

      it 'tracks the snowplow event' do
        post abuse_reports_path(abuse_report: attrs)

        expect_snowplow_event(
          category: 'ReportAbuse',
          action: 'submit_form',
          property: abuse_category,
          user: user
        )
      end
    end

    context 'with invalid attributes' do
      before do
        attrs.delete(:user_id)
      end

      it 'redirects back to root' do
        post abuse_reports_path(abuse_report: attrs)

        expect(response).to redirect_to root_path
      end

      it 'does not track the snowplow event' do
        post abuse_reports_path(abuse_report: attrs)

        expect_no_snowplow_event
      end
    end
  end
end
