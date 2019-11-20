# frozen_string_literal: true

require 'spec_helper'

describe Bitbucket::Connection do
  before do
    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:provider).and_return(double(app_id: '', app_secret: ''))
    end
  end

  describe '#get' do
    it 'calls OAuth2::AccessToken::get' do
      expect_next_instance_of(OAuth2::AccessToken) do |instance|
        expect(instance).to receive(:get).and_return(double(parsed: true))
      end

      connection = described_class.new({})

      connection.get('/users')
    end
  end

  describe '#expired?' do
    it 'calls connection.expired?' do
      expect_next_instance_of(OAuth2::AccessToken) do |instance|
        expect(instance).to receive(:expired?).and_return(true)
      end

      expect(described_class.new({}).expired?).to be_truthy
    end
  end

  describe '#refresh!' do
    it 'calls connection.refresh!' do
      response = double(token: nil, expires_at: nil, expires_in: nil, refresh_token: nil)

      expect_next_instance_of(OAuth2::AccessToken) do |instance|
        expect(instance).to receive(:refresh!).and_return(response)
      end

      described_class.new({}).refresh!
    end
  end
end
