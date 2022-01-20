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
    allow(described_class).to receive(:load_yaml).and_return(configs)
    described_class.instance_variable_set(:@enabled_configs, nil)
  end

  after do
    described_class.instance_variable_set(:@enabled_configs, nil)
  end

  describe '#enabled_configs' do
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
        expect(described_class.enabled_configs.each_value.first[:port]).to eq(Gitlab::MailRoom::DEFAULT_CONFIG[:port])
      end
    end

    context 'when only incoming_email config is present' do
      let(:configs) { { incoming_email: incoming_email_config } }

      it 'returns only encoming_email' do
        expect(described_class.enabled_configs.size).to eq(1)
        expect(described_class.enabled_configs.each_value.first[:worker]).to eq('EmailReceiverWorker')
      end
    end

    describe 'setting up redis settings' do
      let(:fake_redis_queues) { double(url: "localhost", db: 99, sentinels: "yes, them", sentinels?: true) }

      before do
        allow(Gitlab::Redis::Queues).to receive(:new).and_return(fake_redis_queues)
      end

      it 'sets redis config' do
        config = described_class.enabled_configs.each_value.first
        expect(config).to include(
          redis_url: 'localhost',
          redis_db: 99,
          sentinels: 'yes, them'
        )
      end
    end

    describe 'setting up the log path' do
      context 'if the log path is a relative path' do
        let(:custom_config) { { log_path: 'tiny_log.log' } }

        it 'expands the log path to an absolute value' do
          new_path = Pathname.new(described_class.enabled_configs.each_value.first[:log_path])
          expect(new_path.absolute?).to be_truthy
        end
      end

      context 'if the log path is absolute path' do
        let(:custom_config) { { log_path: '/dev/null' } }

        it 'leaves the path as-is' do
          expect(described_class.enabled_configs.each_value.first[:log_path]).to eq '/dev/null'
        end
      end
    end
  end

  describe '#enabled_mailbox_types' do
    context 'when all mailbox types are enabled' do
      it 'returns the mailbox types' do
        expect(described_class.enabled_mailbox_types).to match(%w[incoming_email service_desk_email])
      end
    end

    context 'when an mailbox_types is disabled' do
      let(:incoming_email_config) { yml_config.merge(enabled: false) }

      it 'returns the mailbox types' do
        expect(described_class.enabled_mailbox_types).to match(%w[service_desk_email])
      end
    end

    context 'when email is disabled' do
      let(:custom_config) { { enabled: false } }

      it 'returns an empty array' do
        expect(described_class.enabled_mailbox_types).to match_array([])
      end
    end
  end

  describe '#worker_for' do
    context 'matched mailbox types' do
      it 'returns the constantized worker class' do
        expect(described_class.worker_for('incoming_email')).to eql(EmailReceiverWorker)
        expect(described_class.worker_for('service_desk_email')).to eql(ServiceDeskEmailReceiverWorker)
      end
    end

    context 'non-existing mailbox_type' do
      it 'returns nil' do
        expect(described_class.worker_for('another_mailbox_type')).to be(nil)
      end
    end
  end
end
