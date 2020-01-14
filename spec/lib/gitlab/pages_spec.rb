# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Pages do
  using RSpec::Parameterized::TableSyntax

  let(:pages_secret) { SecureRandom.random_bytes(Gitlab::Pages::SECRET_LENGTH) }

  before do
    allow(described_class).to receive(:secret).and_return(pages_secret)
  end

  describe '.verify_api_request' do
    let(:payload) { { 'iss' => 'gitlab-pages' } }

    it 'returns false if fails to validate the JWT' do
      encoded_token = JWT.encode(payload, 'wrongsecret', 'HS256')
      headers = { described_class::INTERNAL_API_REQUEST_HEADER => encoded_token }

      expect(described_class.verify_api_request(headers)).to eq(false)
    end

    it 'returns the decoded JWT' do
      encoded_token = JWT.encode(payload, described_class.secret, 'HS256')
      headers = { described_class::INTERNAL_API_REQUEST_HEADER => encoded_token }

      expect(described_class.verify_api_request(headers)).to eq([{ "iss" => "gitlab-pages" }, { "alg" => "HS256" }])
    end
  end

  describe '.access_control_is_forced?' do
    subject { described_class.access_control_is_forced? }

    where(:access_control_is_enabled, :access_control_is_forced, :result) do
      false | false | false
      false | true  | false
      true  | false | false
      true  | true  | true
    end

    with_them do
      before do
        stub_pages_setting(access_control: access_control_is_enabled)
        stub_application_setting(force_pages_access_control: access_control_is_forced)
      end

      it { is_expected.to eq(result) }
    end
  end
end
