# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::IdentityVerification, feature_category: :system_access do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  describe 'verification_instructions_email' do
    let_it_be(:user) { build_stubbed(:user) }
    let_it_be(:email) { user.email }
    let_it_be(:token) { '123456' }

    subject(:mail) { Notify.verification_instructions_email(email, token: token) }

    it_behaves_like 'an email sent from GitLab'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject s_('IdentityVerification|Verify your identity')
    end

    it 'has the mailgun suppression bypass header' do
      is_expected.to have_header 'X-Mailgun-Suppressions-Bypass', 'true'
    end

    it 'includes the token' do
      is_expected.to have_body_text token
    end

    it 'includes the expiration time' do
      expires_in_minutes = Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES

      is_expected.to have_body_text format(s_('IdentityVerification|Your verification code expires after '\
        '%{expires_in_minutes} minutes.'), expires_in_minutes: expires_in_minutes)
    end

    context 'with an email containing multiple addresses' do
      let(:email) { 'foo@bar.com,bar@foo.com' }

      it 'raises an error' do
        expect { mail.deliver_now }.to raise_error(Gitlab::Email::MultipleRecipientsError)
      end
    end
  end
end
