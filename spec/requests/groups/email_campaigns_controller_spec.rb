# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::EmailCampaignsController do
  using RSpec::Parameterized::TableSyntax

  describe 'GET #index', :snowplow do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:user) { create(:user) }

    let(:track) { 'create' }
    let(:series) { '0' }
    let(:schema) { described_class::EMAIL_CAMPAIGNS_SCHEMA_URL }
    let(:subject_line_text) { Gitlab::Email::Message::InProductMarketing.for(track.to_sym).new(group: group, user: user, series: series.to_i).subject_line }
    let(:data) do
      {
        namespace_id: group.id,
        track: track.to_sym,
        series: series.to_i,
        subject_line: subject_line_text
      }
    end

    before do
      sign_in(user)
      group.add_developer(user)
    end

    subject do
      get group_email_campaigns_url(group, track: track, series: series)
      response
    end

    shared_examples 'track and redirect' do
      it 'redirects' do
        expect(subject).to have_gitlab_http_status(:redirect)
      end

      context 'on .com' do
        before do
          allow(Gitlab).to receive(:com?).and_return(true)
        end

        it 'emits a snowplow event', :snowplow do
          subject

          expect_snowplow_event(
            category: described_class.name,
            action: 'click',
            context: [{
                        schema: described_class::EMAIL_CAMPAIGNS_SCHEMA_URL,
                        data: { namespace_id: group.id, series: series.to_i, subject_line: subject_line_text, track: track.to_s }
                      }],
            user: user,
            namespace: group
          )
        end

        it 'does not save the cta_click' do
          expect(Users::InProductMarketingEmail).not_to receive(:save_cta_click)

          subject
        end
      end

      context 'when not on.com' do
        it 'saves the cta_click' do
          expect(Users::InProductMarketingEmail).to receive(:save_cta_click)

          subject
        end

        it 'does not track snowplow events' do
          subject

          expect_no_snowplow_event
        end
      end
    end

    shared_examples 'no track and 404' do
      it 'returns 404' do
        expect(subject).to have_gitlab_http_status(:not_found)
      end

      it 'does not emit a snowplow event', :snowplow do
        subject

        expect_no_snowplow_event
      end
    end

    describe 'track parameter' do
      context 'when valid' do
        where(track: Namespaces::InProductMarketingEmailsService::TRACKS.keys.without(:experience))

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
        where(series: (0..Namespaces::InProductMarketingEmailsService::TRACKS[:create][:interval_days].length - 1).to_a)

        with_them do
          it_behaves_like 'track and redirect'
        end
      end

      context 'when invalid' do
        where(series: [-1, nil, Namespaces::InProductMarketingEmailsService::TRACKS[:create][:interval_days].length])

        with_them do
          it_behaves_like 'no track and 404'
        end
      end
    end
  end
end
