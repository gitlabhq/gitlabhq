require 'spec_helper'

describe Gitlab::Redis do
  let(:redis_config) { Rails.root.join('config', 'resque.yml').to_s }

  before(:each) { clear_raw_config }
  after(:each) { clear_raw_config }

  describe '.params' do
    subject { described_class.params }

    it 'withstands mutation' do
      params1 = described_class.params
      params2 = described_class.params
      params1[:foo] = :bar

      expect(params2).not_to have_key(:foo)
    end

    context 'when url contains unix socket reference' do
      let(:config_old) { Rails.root.join('spec/fixtures/config/redis_old_format_socket.yml').to_s }
      let(:config_new) { Rails.root.join('spec/fixtures/config/redis_new_format_socket.yml').to_s }

      context 'with old format' do
        it 'returns path key instead' do
          stub_const("#{described_class}::CONFIG_FILE", config_old)

          is_expected.to include(path: '/path/to/old/redis.sock')
          is_expected.not_to have_key(:url)
        end
      end

      context 'with new format' do
        it 'returns path key instead' do
          stub_const("#{described_class}::CONFIG_FILE", config_new)

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
          stub_const("#{described_class}::CONFIG_FILE", config_old)

          is_expected.to include(host: 'localhost', password: 'mypassword', port: 6379, db: 99)
          is_expected.not_to have_key(:url)
        end
      end

      context 'with new format' do
        it 'returns hash with host, port, db, and password' do
          stub_const("#{described_class}::CONFIG_FILE", config_new)

          is_expected.to include(host: 'localhost', password: 'mynewpassword', port: 6379, db: 99)
          is_expected.not_to have_key(:url)
        end
      end
    end
  end

  describe '.url' do
    it 'withstands mutation' do
      url1 = described_class.url
      url2 = described_class.url
      url1 << 'foobar'

      expect(url2).not_to end_with('foobar')
    end
  end

  describe '._raw_config' do
    subject { described_class._raw_config }

    it 'should be frozen' do
      expect(subject).to be_frozen
    end

    it 'returns false when the file does not exist' do
      stub_const("#{described_class}::CONFIG_FILE", '/var/empty/doesnotexist')

      expect(subject).to eq(false)
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
      allow(described_class).to receive(:_raw_config) { false }

      expect(subject.send(:fetch_config)).to be_falsey
    end
  end

  def clear_raw_config
    described_class.remove_instance_variable(:@_raw_config)
  rescue NameError
    # raised if @_raw_config was not set; ignore
  end
end
