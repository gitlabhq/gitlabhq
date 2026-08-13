# frozen_string_literal: true

require 'spec_helper'
require 'apnotic' # require: false in the Gemfile; the client requires it lazily

RSpec.describe Gitlab::MobilePush::ApnsClient, feature_category: :notifications do
  subject(:client) do
    described_class.new(auth_key_path: '/tmp/key.p8', key_id: 'KEYID12345', team_id: 'TEAM123456')
  end

  let(:connection) { instance_double(Apnotic::Connection, push: response, close: nil) }
  let(:response) { instance_double(Apnotic::Response, ok?: true) }
  let(:payload) do
    instance_double(
      Gitlab::MobilePush::Payload,
      title: 'T', subtitle: 'S', body: 'B', badge: 1, thread_id: 'th',
      collapse_id: 'todo-1', mutable_content?: true, gitlab_data: { version: 1 }
    )
  end

  describe 'configuration' do
    it 'reads credentials from gitlab.yml mobile_push.apns settings by default' do
      stub_config(
        mobile_push: { apns: { auth_key_path: '/tmp/key.p8', key_id: 'K', team_id: 'T', topic: 'custom.topic' } }
      )

      expect(described_class.new).to be_configured
    end

    it 'is not configured when the settings are absent' do
      expect(described_class.new).not_to be_configured
    end
  end

  describe '#push connection reuse' do
    it 'opens one connection per APNs environment and reuses it across pushes' do
      sandbox_one = build_stubbed(:mobile_device_push_subscription, :sandbox)
      sandbox_two = build_stubbed(:mobile_device_push_subscription, :sandbox)
      production = build_stubbed(:mobile_device_push_subscription)

      expect(Apnotic::Connection).to receive(:development).once.and_return(connection)
      expect(Apnotic::Connection).to receive(:new).once.and_return(connection)

      client.push(sandbox_one, payload)
      client.push(sandbox_two, payload)
      client.push(production, payload)
    end
  end

  describe '#close' do
    it 'closes every opened connection' do
      subscription = build_stubbed(:mobile_device_push_subscription, :sandbox)
      allow(Apnotic::Connection).to receive(:development).and_return(connection)

      client.push(subscription, payload)
      client.close

      expect(connection).to have_received(:close)
    end
  end
end
