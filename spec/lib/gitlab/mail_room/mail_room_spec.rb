# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MailRoom do
  let(:default_port) { 143 }
  let(:yml_config) do
    {
      enabled: true,
      address: 'address@example.com',
      port: default_port,
      ssl: false,
      start_tls: false,
      mailbox: 'inbox',
      idle_timeout: 60,
      log_path: Rails.root.join('log', 'mail_room_json.log').to_s,
      expunge_deleted: false
    }
  end

  let(:custom_config) { {} }
  let(:incoming_email_config) { yml_config.merge(custom_config) }
  let(:service_desk_email_config) { yml_config.merge(custom_config) }

  let(:configs) do
    {
      incoming_email: incoming_email_config,
      service_desk_email: service_desk_email_config
    }
  end

  before do
    described_class.instance_variable_set(:@enabled_configs, nil)
  end

  after do
    described_class.instance_variable_set(:@enabled_configs, nil)
  end

  describe '#enabled_configs' do
    before do
      allow(described_class).to receive(:load_yaml).and_return(configs)
    end

    context 'when both email and address is set' do
      it 'returns email configs' do
        expect(described_class.enabled_configs.size).to eq(2)
      end
    end

    context 'when the yml file cannot be found' do
      before do
        allow(described_class).to receive(:config_file).and_return('not_existing_file')
      end

      it 'returns an empty list' do
        expect(described_class.enabled_configs).to be_empty
      end
    end

    context 'when email is disabled' do
      let(:custom_config) { { enabled: false } }

      it 'returns an empty list' do
        expect(described_class.enabled_configs).to be_empty
      end
    end

    context 'when email is enabled but address is not set' do
      let(:custom_config) { { enabled: true, address: '' } }

      it 'returns an empty list' do
        expect(described_class.enabled_configs).to be_empty
      end
    end

    context 'when a config value is missing from the yml file' do
      let(:yml_config) { {} }
      let(:custom_config) { { enabled: true, address: 'address@example.com' } }

      it 'overwrites missing values with the default' do
        expect(described_class.enabled_configs.first[:port]).to eq(Gitlab::MailRoom::DEFAULT_CONFIG[:port])
      end
    end

    context 'when only incoming_email config is present' do
      let(:configs) { { incoming_email: incoming_email_config } }

      it 'returns only encoming_email' do
        expect(described_class.enabled_configs.size).to eq(1)
        expect(described_class.enabled_configs.first[:worker]).to eq('EmailReceiverWorker')
      end
    end

    describe 'setting up redis settings' do
      let(:fake_redis_queues) { double(url: "localhost", sentinels: "yes, them", sentinels?: true) }

      before do
        allow(Gitlab::Redis::Queues).to receive(:new).and_return(fake_redis_queues)
      end

      it 'sets redis config' do
        config = described_class.enabled_configs.first

        expect(config[:redis_url]).to eq('localhost')
        expect(config[:sentinels]).to eq('yes, them')
      end
    end

    describe 'setting up the log path' do
      context 'if the log path is a relative path' do
        let(:custom_config) { { log_path: 'tiny_log.log' } }

        it 'expands the log path to an absolute value' do
          new_path = Pathname.new(described_class.enabled_configs.first[:log_path])
          expect(new_path.absolute?).to be_truthy
        end
      end

      context 'if the log path is absolute path' do
        let(:custom_config) { { log_path: '/dev/null' } }

        it 'leaves the path as-is' do
          expect(described_class.enabled_configs.first[:log_path]).to eq '/dev/null'
        end
      end
    end
  end
end
