# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::EmailCampaignsController do
  include InProductMarketingHelper
  using RSpec::Parameterized::TableSyntax

  describe 'GET #index', :snowplow do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:user) { create(:user) }
    let(:track) { 'create' }
    let(:series) { '0' }
    let(:schema) { described_class::EMAIL_CAMPAIGNS_SCHEMA_URL }
    let(:data) do
      {
        namespace_id: group.id,
        track: track.to_sym,
        series: series.to_i,
        subject_line: subject_line(track.to_sym, series.to_i)
      }
    end

    before do
      sign_in(user)
      group.add_developer(user)
      allow(Gitlab::Tracking).to receive(:self_describing_event)
    end

    subject do
      get group_email_campaigns_url(group, track: track, series: series)
      response
    end

    shared_examples 'track and redirect' do
      it do
        is_expected.to track_self_describing_event(schema, data)
        is_expected.to have_gitlab_http_status(:redirect)
      end
    end

    shared_examples 'no track and 404' do
      it do
        is_expected.not_to track_self_describing_event
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end

    describe 'track parameter' do
      context 'when valid' do
        where(track: Namespaces::InProductMarketingEmailsService::TRACKS.keys)

        with_them do
          it_behaves_like 'track and redirect'
        end
      end

      context 'when invalid' do
        where(track: [nil, 'xxxx'])

        with_them do
          it_behaves_like 'no track and 404'
        end
      end
    end

    describe 'series parameter' do
      context 'when valid' do
        where(series: (0..Namespaces::InProductMarketingEmailsService::INTERVAL_DAYS.length - 1).to_a)

        with_them do
          it_behaves_like 'track and redirect'
        end
      end

      context 'when invalid' do
        where(series: [-1, nil, Namespaces::InProductMarketingEmailsService::INTERVAL_DAYS.length])

        with_them do
          it_behaves_like 'no track and 404'
        end
      end
    end
  end
end
