# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Doctor::Secrets do
  let!(:user) { create(:user, otp_secret: "test") }
  let!(:group) { create(:group, runners_token: "test") }
  let(:logger) { double(:logger).as_null_object }

  subject { described_class.new(logger).run! }

  context 'when encrypted attributes are properly set' do
    it 'detects decryptable secrets' do
      expect(logger).to receive(:info).with(/User failures: 0/)
      expect(logger).to receive(:info).with(/Group failures: 0/)

      subject
    end
  end

  context 'when attr_encrypted values are not decrypting' do
    it 'marks undecryptable values as bad' do
      user.encrypted_otp_secret = "invalid"
      user.save!

      expect(logger).to receive(:info).with(/User failures: 1/)

      subject
    end
  end

  context 'when TokenAuthenticatable values are not decrypting' do
    it 'marks undecryptable values as bad' do
      group.runners_token_encrypted = "invalid"
      group.save!

      expect(logger).to receive(:info).with(/Group failures: 1/)

      subject
    end
  end
end
