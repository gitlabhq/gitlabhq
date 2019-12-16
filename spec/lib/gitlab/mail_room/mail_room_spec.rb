# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::MailRoom do
  let(:default_port) { 143 }
  let(:default_config) do
    {
      enabled: false,
      port: default_port,
      ssl: false,
      start_tls: false,
      mailbox: 'inbox',
      idle_timeout: 60,
      log_path: Rails.root.join('log', 'mail_room_json.log').to_s
    }
  end

  before do
    described_class.reset_config!
    allow(File).to receive(:exist?).and_return true
  end

  describe '#config' do
    context 'if the yml file cannot be found' do
      before do
        allow(File).to receive(:exist?).and_return false
      end

      it 'returns an empty hash' do
        expect(described_class.config).to be_empty
      end
    end

    before do
      allow(described_class).to receive(:load_from_yaml).and_return(default_config)
    end

    it 'sets up config properly' do
      expected_result = default_config

      expect(described_class.config).to match expected_result
    end

    context 'when a config value is missing from the yml file' do
      it 'overwrites missing values with the default' do
        stub_config(port: nil)

        expect(described_class.config[:port]).to eq default_port
      end
    end

    describe 'setting up redis settings' do
      let(:fake_redis_queues) { double(url: "localhost", sentinels: "yes, them", sentinels?: true) }

      before do
        allow(Gitlab::Redis::Queues).to receive(:new).and_return(fake_redis_queues)
      end

      target_proc = proc { described_class.config[:redis_url] }

      it_behaves_like 'only truthy if both enabled and address are truthy', target_proc
    end

    describe 'setting up the log path' do
      context 'if the log path is a relative path' do
        it 'expands the log path to an absolute value' do
          stub_config(log_path: 'tiny_log.log')

          new_path = Pathname.new(described_class.config[:log_path])
          expect(new_path.absolute?).to be_truthy
        end
      end

      context 'if the log path is absolute path' do
        it 'leaves the path as-is' do
          new_path = '/dev/null'
          stub_config(log_path: new_path)

          expect(described_class.config[:log_path]).to eq new_path
        end
      end
    end
  end

  describe '#enabled?' do
    target_proc = proc { described_class.enabled? }

    it_behaves_like 'only truthy if both enabled and address are truthy', target_proc
  end

  describe '#reset_config?' do
    it 'resets config' do
      described_class.instance_variable_set(:@config, { some_stuff: 'hooray' })

      described_class.reset_config!

      expect(described_class.instance_variable_get(:@config)).to be_nil
    end
  end

  def stub_config(override_values)
    modified_config = default_config.merge(override_values)
    allow(described_class).to receive(:load_from_yaml).and_return(modified_config)
  end
end
