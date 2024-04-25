# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bitbucket::Connection, feature_category: :integrations do
  subject(:bitbucket_connection) { described_class.new(options) }

  let(:options) do
    {
      token: 'foo',
      refresh_token: 'bar',
      expires_in: 7200
    }
  end

  describe '#connection' do
    context 'when oauth' do
      it 'uses OAuth connection' do
        expect(bitbucket_connection.connection).to be_an_instance_of(Bitbucket::OauthConnection)
      end
    end

    context 'when app password' do
      let(:options) do
        {
          username: 'foo',
          app_password: 'bar'
        }
      end

      it 'uses App Password connection' do
        expect(bitbucket_connection.connection).to be_an_instance_of(Bitbucket::AppPasswordConnection)
      end
    end
  end

  describe '#get' do
    it 'delegates to underlying connection' do
      expect_next_instance_of(Bitbucket::OauthConnection) do |connection|
        expect(connection).to receive(:get)
      end

      bitbucket_connection.get
    end
  end
end
