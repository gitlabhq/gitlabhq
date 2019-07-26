# frozen_string_literal: true

require 'spec_helper'

describe Bitbucket::Connection do
  before do
    allow_any_instance_of(described_class).to receive(:provider).and_return(double(app_id: '', app_secret: ''))
  end

  describe '#get' do
    it 'calls OAuth2::AccessToken::get' do
      expect_any_instance_of(OAuth2::AccessToken).to receive(:get).and_return(double(parsed: true))

      connection = described_class.new({})

      connection.get('/users')
    end
  end

  describe '#expired?' do
    it 'calls connection.expired?' do
      expect_any_instance_of(OAuth2::AccessToken).to receive(:expired?).and_return(true)

      expect(described_class.new({}).expired?).to be_truthy
    end
  end

  describe '#refresh!' do
    it 'calls connection.refresh!' do
      response = double(token: nil, expires_at: nil, expires_in: nil, refresh_token: nil)

      expect_any_instance_of(OAuth2::AccessToken).to receive(:refresh!).and_return(response)

      described_class.new({}).refresh!
    end
  end
end
