require 'spec_helper'

describe Gitlab::Redis do
  let(:redis_config) { Rails.root.join('config', 'resque.yml').to_s }

  before(:each) { described_class.reset_params! }
  after(:each) { described_class.reset_params! }

  describe '.params' do
    subject { described_class.params }

    context 'when url contains unix socket reference' do
      let(:config_old) { Rails.root.join('spec/fixtures/config/redis_old_format_socket.yml').to_s }
      let(:config_new) { Rails.root.join('spec/fixtures/config/redis_new_format_socket.yml').to_s }

      context 'with old format' do
        it 'returns path key instead' do
          expect_any_instance_of(described_class).to receive(:config_file) { config_old }

          is_expected.to include(path: '/path/to/old/redis.sock')
          is_expected.not_to have_key(:url)
        end
      end

      context 'with new format' do
        it 'returns path key instead' do
          expect_any_instance_of(described_class).to receive(:config_file) { config_new }

          is_expected.to include(path: '/path/to/redis.sock')
          is_expected.not_to have_key(:url)
        end
      end
    end

    context 'when url is host based' do
      let(:config_old) { Rails.root.join('spec/fixtures/config/redis_old_format_host.yml') }
      let(:config_new) { Rails.root.join('spec/fixtures/config/redis_new_format_host.yml') }

      context 'with old format' do
        it 'returns hash with host, port, db, and password' do
          expect_any_instance_of(described_class).to receive(:config_file) { config_old }

          is_expected.to include(host: 'localhost', password: 'mypassword', port: 6379, db: 99)
          is_expected.not_to have_key(:url)
        end
      end

      context 'with new format' do
        it 'returns hash with host, port, db, and password' do
          expect_any_instance_of(described_class).to receive(:config_file) { config_new }

          is_expected.to include(host: 'localhost', password: 'mynewpassword', port: 6379, db: 99)
          is_expected.not_to have_key(:url)
        end
      end
    end
  end

  describe '#raw_config_hash' do
    it 'returns default redis url when no config file is present' do
      expect(subject).to receive(:fetch_config) { false }

      expect(subject.send(:raw_config_hash)).to eq(url: Gitlab::Redis::DEFAULT_REDIS_URL)
    end

    it 'returns old-style single url config in a hash' do
      expect(subject).to receive(:fetch_config) { 'redis://myredis:6379' }
      expect(subject.send(:raw_config_hash)).to eq(url: 'redis://myredis:6379')
    end
  end

  describe '#fetch_config' do
    it 'returns false when no config file is present' do
      allow(File).to receive(:exist?).with(redis_config) { false }

      expect(subject.send(:fetch_config)).to be_falsey
    end
  end
end
