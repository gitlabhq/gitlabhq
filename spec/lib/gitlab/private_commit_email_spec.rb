# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PrivateCommitEmail, feature_category: :shared do
  let(:hostname) { Gitlab::CurrentSettings.current_application_settings.commit_email_hostname }
  let(:id) { 1 }
  let(:valid_email) { "#{id}-foo@#{hostname}" }
  let(:invalid_email) { "#{id}-foo@users.noreply.bar.com" }

  describe '.regex', :request_store do
    subject { described_class.regex }

    it { is_expected.to match("1-foo@#{hostname}") }
    it { is_expected.to match("1-BLAH@#{hostname}") }
    it { is_expected.not_to match("1-foo@#{hostname}.foo") }
    it { is_expected.not_to match('1-foo@users.noreply.gitlab.com') }
    it { is_expected.not_to match('foo-1@users.noreply.gitlab.com') }
    it { is_expected.not_to match('foobar@gitlab.com') }

    it 'is only generated once per request' do
      expect(Regexp).to receive(:escape).once

      2.times { described_class.regex }
    end
  end

  describe '.user_id_for_email' do
    it 'parses user id from email' do
      expect(described_class.user_id_for_email(valid_email)).to eq(id)
    end

    it 'returns nil on invalid commit email' do
      expect(described_class.user_id_for_email(invalid_email)).to be_nil
    end
  end

  describe '.user_ids_for_email' do
    it 'returns deduplicated user IDs for each valid email' do
      result = described_class.user_ids_for_emails([valid_email, valid_email, invalid_email])

      expect(result).to eq([id])
    end

    it 'returns an empty array with no valid emails' do
      result = described_class.user_ids_for_emails([invalid_email])
      expect(result).to eq([])
    end
  end

  describe '.for_user' do
    it 'returns email in the format id-username@hostname' do
      user = create(:user)

      expect(described_class.for_user(user)).to eq("#{user.id}-#{user.username}@#{hostname}")
    end

    it 'stores the private commit email with uppercase' do
      user = create(:user, username: 'BOBBY_TABLES')

      expect(described_class.for_user(user)).to eq("#{user.id}-BOBBY_TABLES@#{hostname}")
    end
  end
end
