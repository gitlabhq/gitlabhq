RSpec.shared_examples "redis_shared_examples" do
  include StubENV

  let(:test_redis_url)  { "redis://redishost:#{redis_port}"}

  before do
    stub_env(environment_config_file_name, Rails.root.join(config_file_name))
    clear_raw_config
  end

  after do
    clear_raw_config
  end

  describe '.params' do
    subject { described_class.params }

    it 'withstands mutation' do
      params1 = described_class.params
      params2 = described_class.params
      params1[:foo] = :bar

      expect(params2).not_to have_key(:foo)
    end

    context 'when url contains unix socket reference' do
      context 'with old format' do
        let(:config_file_name) { config_old_format_socket }

        it 'returns path key instead' do
          is_expected.to include(path: old_socket_path)
          is_expected.not_to have_key(:url)
        end
      end

      context 'with new format' do
        let(:config_file_name) { config_new_format_socket }

        it 'returns path key instead' do
          is_expected.to include(path: new_socket_path)
          is_expected.not_to have_key(:url)
        end
      end
    end

    context 'when url is host based' do
      context 'with old format' do
        let(:config_file_name) { config_old_format_host }

        it 'returns hash with host, port, db, and password' do
          is_expected.to include(host: 'localhost', password: 'mypassword', port: redis_port, db: redis_database)
          is_expected.not_to have_key(:url)
        end
      end

      context 'with new format' do
        let(:config_file_name) { config_new_format_host }

        it 'returns hash with host, port, db, and password' do
          is_expected.to include(host: 'localhost', password: 'mynewpassword', port: redis_port, db: redis_database)
          is_expected.not_to have_key(:url)
        end
      end
    end
  end

  describe '.url' do
    context 'when yml file with env variable' do
      let(:config_file_name) { config_with_environment_variable_inside }

      before  do
        stub_env(config_env_variable_url, test_redis_url)
      end

      it 'reads redis url from env variable' do
        expect(described_class.url).to eq test_redis_url
      end
    end
  end

  describe '._raw_config' do
    subject { described_class._raw_config }
    let(:config_file_name) { '/var/empty/doesnotexist' }

    it 'should be frozen' do
      expect(subject).to be_frozen
    end

    it 'returns false when the file does not exist' do
      expect(subject).to eq(false)
    end

    it "returns false when the filename can't be determined" do
      expect(described_class).to receive(:config_file_name).and_return(nil)

      expect(subject).to eq(false)
    end
  end

  describe '.with' do
    before do
      clear_pool
    end

    after do
      clear_pool
    end

    context 'when running not on sidekiq workers' do
      before do
        allow(Sidekiq).to receive(:server?).and_return(false)
      end

      it 'instantiates a connection pool with size 5' do
        expect(ConnectionPool).to receive(:new).with(size: 5).and_call_original

        described_class.with { |_redis_shared_example| true }
      end
    end

    context 'when running on sidekiq workers' do
      before do
        allow(Sidekiq).to receive(:server?).and_return(true)
        allow(Sidekiq).to receive(:options).and_return({ concurrency: 18 })
      end

      it 'instantiates a connection pool with a size based on the concurrency of the worker' do
        expect(ConnectionPool).to receive(:new).with(size: 18 + 5).and_call_original

        described_class.with { |_redis_shared_example| true }
      end
    end
  end

  describe '#sentinels' do
    subject { described_class.new(Rails.env).sentinels }

    context 'when sentinels are defined' do
      let(:config_file_name) { config_new_format_host }

      it 'returns an array of hashes with host and port keys' do
        is_expected.to include(host: 'localhost', port: sentinel_port)
        is_expected.to include(host: 'slave2', port: sentinel_port)
      end
    end

    context 'when sentinels are not defined' do
      let(:config_file_name) { config_old_format_host }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#sentinels?' do
    subject { described_class.new(Rails.env).sentinels? }

    context 'when sentinels are defined' do
      let(:config_file_name) { config_new_format_host }

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'when sentinels are not defined' do
      let(:config_file_name) { config_old_format_host }

      it 'returns false' do
        is_expected.to be_falsey
      end
    end
  end

  describe '#raw_config_hash' do
    it 'returns default redis url when no config file is present' do
      expect(subject).to receive(:fetch_config) { false }

      expect(subject.send(:raw_config_hash)).to eq(url: class_redis_url )
    end

    it 'returns old-style single url config in a hash' do
      expect(subject).to receive(:fetch_config) { test_redis_url }
      expect(subject.send(:raw_config_hash)).to eq(url: test_redis_url)
    end
  end

  describe '#fetch_config' do
    it 'returns false when no config file is present' do
      allow(described_class).to receive(:_raw_config) { false }

      expect(subject.send(:fetch_config)).to eq false
    end

    it 'returns false when config file is present but has invalid YAML' do
      allow(described_class).to receive(:_raw_config) { "# development: true" }

      expect(subject.send(:fetch_config)).to eq false
    end
  end

  def clear_raw_config
    described_class.remove_instance_variable(:@_raw_config)
  rescue NameError
    # raised if @_raw_config was not set; ignore
  end

  def clear_pool
    described_class.remove_instance_variable(:@pool)
  rescue NameError
    # raised if @pool was not set; ignore
  end
end
