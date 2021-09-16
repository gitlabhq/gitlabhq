# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::InProductMarketing do
  include EmailSpec::Matchers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let!(:onboarding_progress) { create(:onboarding_progress, namespace: group) }

  describe '#in_product_marketing_email' do
    using RSpec::Parameterized::TableSyntax

    let(:track) { :create }
    let(:series) { 0 }

    subject { Notify.in_product_marketing_email(user.id, group.id, track, series) }

    include_context 'gitlab email notification'

    it 'sends to the right user with a link to unsubscribe' do
      aggregate_failures do
        expect(subject).to deliver_to(user.notification_email)
        expect(subject).to have_body_text(profile_notifications_url)
      end
    end

    context 'when on gitlab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'has custom headers' do
        aggregate_failures do
          expect(subject).to deliver_from(described_class::FROM_ADDRESS)
          expect(subject).to reply_to(described_class::FROM_ADDRESS)
          expect(subject).to have_header('X-Mailgun-Track', 'yes')
          expect(subject).to have_header('X-Mailgun-Track-Clicks', 'yes')
          expect(subject).to have_header('X-Mailgun-Track-Opens', 'yes')
          expect(subject).to have_header('X-Mailgun-Tag', 'marketing')
          expect(subject).to have_body_text('%tag_unsubscribe_url%')
        end
      end
    end

    where(:track, :series) do
      :create     | 0
      :create     | 1
      :create     | 2
      :verify     | 0
      :verify     | 1
      :verify     | 2
      :trial      | 0
      :trial      | 1
      :trial      | 2
      :team       | 0
      :team       | 1
      :team       | 2
      :experience | 0
    end

    with_them do
      it 'has the correct subject and content' do
        message = Gitlab::Email::Message::InProductMarketing.for(track).new(group: group, user: user, series: series)

        aggregate_failures do
          is_expected.to have_subject(message.subject_line)
          is_expected.to have_body_text(message.title)
          is_expected.to have_body_text(message.subtitle)

          if track == :experience
            is_expected.to have_body_text(CGI.unescapeHTML(message.feedback_link(1)))
          else
            is_expected.to have_body_text(CGI.unescapeHTML(message.cta_link))
          end
        end
      end
    end
  end
end
