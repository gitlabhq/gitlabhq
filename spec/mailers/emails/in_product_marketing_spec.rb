# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::InProductMarketing do
  include EmailSpec::Matchers
  include Gitlab::Routing.url_helpers

  let_it_be(:user) { create(:user) }

  shared_examples 'has custom headers when on gitlab.com' do
    context 'when on gitlab.com', :saas do
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
  end

  describe '#build_ios_app_guide_email' do
    subject { Notify.build_ios_app_guide_email(user.notification_email_or_default) }

    it 'sends to the right user' do
      expect(subject).to deliver_to(user.notification_email_or_default)
    end

    it 'has the correct subject and content' do
      message = Gitlab::Email::Message::BuildIosAppGuide.new
      cta_url = 'https://about.gitlab.com/blog/2019/03/06/ios-publishing-with-gitlab-and-fastlane/'
      cta2_url = 'https://www.youtube.com/watch?v=325FyJt7ZG8'

      aggregate_failures do
        is_expected.to have_subject(message.subject_line)
        is_expected.to have_body_text(message.title)
        is_expected.to have_body_text(message.body_line1)
        is_expected.to have_body_text(CGI.unescapeHTML(message.cta_link))
        is_expected.to have_body_text(CGI.unescapeHTML(message.cta2_link))
        is_expected.to have_body_text(cta_url)
        is_expected.to have_body_text(cta2_url)
      end
    end
  end
end
