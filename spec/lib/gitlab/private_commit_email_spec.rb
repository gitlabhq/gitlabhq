# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::PrivateCommitEmail do
  let(:hostname) { Gitlab::CurrentSettings.current_application_settings.commit_email_hostname }

  context '.regex' do
    subject { described_class.regex }

    it { is_expected.to match("1-foo@#{hostname}") }
    it { is_expected.not_to match("1-foo@#{hostname}.foo") }
    it { is_expected.not_to match('1-foo@users.noreply.gitlab.com') }
    it { is_expected.not_to match('foo-1@users.noreply.gitlab.com') }
    it { is_expected.not_to match('foobar@gitlab.com') }
  end

  context '.user_id_for_email' do
    let(:id) { 1 }

    it 'parses user id from email' do
      email = "#{id}-foo@#{hostname}"

      expect(described_class.user_id_for_email(email)).to eq(id)
    end

    it 'returns nil on invalid commit email' do
      email = "#{id}-foo@users.noreply.bar.com"

      expect(described_class.user_id_for_email(email)).to be_nil
    end
  end

  context '.for_user' do
    it 'returns email in the format id-username@hostname' do
      user = create(:user)

      expect(described_class.for_user(user)).to eq("#{user.id}-#{user.username}@#{hostname}")
    end
  end
end
