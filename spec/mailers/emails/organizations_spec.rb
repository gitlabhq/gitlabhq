# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::Organizations, feature_category: :organization do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Need persisted records for the mailer lookups
  let_it_be(:user) { create(:user) }
  let_it_be(:organization) { create(:organization, owners: user) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  describe '#organization_activated_email' do
    subject(:email) { Notify.organization_activated_email(organization.id, user.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'is sent to the confirming user' do
      is_expected.to deliver_to(user.notification_email_or_default)
    end

    it 'has the correct subject and body' do
      is_expected.to have_subject("Your organization #{organization.name} is ready")
      is_expected.to have_body_text("Your organization #{organization.name} is ready.")
      is_expected.to have_body_text(organization.web_url)
    end

    context 'when the organization name contains a character that HTML escapes' do
      # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Need persisted records for the mailer lookups
      let_it_be(:organization) { create(:organization, name: 'Foo & Bar', owners: user) }
      # rubocop:enable RSpec/FactoryBot/AvoidCreate

      it 'does not escape the name in the subject or the text part', :aggregate_failures do
        expect(email.subject).to eq('Your organization Foo & Bar is ready')
        expect(email.text_part.body.to_s).to include('Your organization Foo & Bar is ready.')
      end
    end

    context 'when the organization no longer exists' do
      subject(:email) { Notify.organization_activated_email(non_existing_record_id, user.id) }

      it 'returns NullMail' do
        expect(email.message).to be_a_kind_of(ActionMailer::Base::NullMail)
      end
    end

    context 'when the user no longer exists' do
      subject(:email) { Notify.organization_activated_email(organization.id, non_existing_record_id) }

      it 'returns NullMail' do
        expect(email.message).to be_a_kind_of(ActionMailer::Base::NullMail)
      end
    end
  end
end
