# frozen_string_literal: true

RSpec.shared_examples "redis_shared_examples" do
  include StubENV

  let(:test_redis_url) { "redis://redishost:#{redis_port}"}
  let(:config_file_name) { instance_specific_config_file }
  let(:config_old_format_socket) { "spec/fixtures/config/redis_old_format_socket.yml" }
  let(:config_new_format_socket) { "spec/fixtures/config/redis_new_format_socket.yml" }
  let(:old_socket_path) {"/path/to/old/redis.sock" }
  let(:new_socket_path) {"/path/to/redis.sock" }
  let(:config_old_format_host) { "spec/fixtures/config/redis_old_format_host.yml" }
  let(:config_new_format_host) { "spec/fixtures/config/redis_new_format_host.yml" }
  let(:redis_port) { 6379 }
  let(:redis_database) { 99 }
  let(:sentinel_port) { 26379 }
  let(:config_with_environment_variable_inside) { "spec/fixtures/config/redis_config_with_env.yml"}
  let(:config_env_variable_url) {"TEST_GITLAB_REDIS_URL"}
  let(:rails_root) { Dir.mktmpdir('redis_shared_examples') }

  before do
    allow(described_class).to receive(:config_file_name).and_return(Rails.root.join(config_file_name).to_s)
    clear_raw_config
  end

  after do
    clear_raw_config
  end

  describe '.config_file_name' do
    subject { described_class.config_file_name }

    before do
      # Undo top-level stub of config_file_name because we are testing that method now.
      allow(described_class).to receive(:config_file_name).and_call_original

      allow(described_class).to receive(:rails_root).and_return(rails_root)
      FileUtils.mkdir_p(File.join(rails_root, 'config'))
    end

    after do
      FileUtils.rm_rf(rails_root)
    end

    context 'when there is no config file anywhere' do
      it { expect(subject).to be_nil }

      context 'but resque.yml exists' do
        before do
          FileUtils.touch(File.join(rails_root, 'config', 'resque.yml'))
        end

        it { expect(subject).to eq("#{rails_root}/config/resque.yml") }

        it 'returns a path that exists' do
          expect(File.file?(subject)).to eq(true)
        end

        context 'and there is a global env override' do
          before do
            stub_env('GITLAB_REDIS_CONFIG_FILE', 'global override')
          end

          it { expect(subject).to eq('global override') }

          context 'and there is an instance specific config file' do
            before do
              FileUtils.touch(File.join(rails_root, instance_specific_config_file))
            end

            it { expect(subject).to eq("#{rails_root}/#{instance_specific_config_file}") }

            it 'returns a path that exists' do
              expect(File.file?(subject)).to eq(true)
            end

            context 'and there is a specific env override' do
              before do
                stub_env(environment_config_file_name, 'instance specific override')
              end

              it { expect(subject).to eq('instance specific override') }
            end
          end
        end
      end
    end
  end

  describe '.params' do
    subject { described_class.new(rails_env).params }

    let(:rails_env) { 'development' }
    let(:config_file_name) { config_old_format_socket }

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

        where(:rails_env, :host) do
          [
            %w[development development-host],
            %w[test test-host],
            %w[production production-host]
          ]
        end

        with_them do
          it 'returns hash with host, port, db, and password' do
            is_expected.to include(host: host, password: 'mynewpassword', port: redis_port, db: redis_database)
            is_expected.not_to have_key(:url)
          end
        end
      end
    end
  end

  describe '.url' do
    let(:config_file_name) { config_old_format_socket }

    it 'withstands mutation' do
      url1 = described_class.url
      url2 = described_class.url
      url1 << 'foobar' unless url1.frozen?

      expect(url2).not_to end_with('foobar')
    end

    context 'when yml file with env variable' do
      let(:config_file_name) { config_with_environment_variable_inside }

      before do
        stub_env(config_env_variable_url, test_redis_url)
      end

      it 'reads redis url from env variable' do
        expect(described_class.url).to eq test_redis_url
      end
    end
  end

  describe '.version' do
    it 'returns a version' do
      expect(described_class.version).to be_present
    end
  end

  describe '._raw_config' do
    subject { described_class._raw_config }

    let(:config_file_name) { '/var/empty/doesnotexist' }

    it 'is frozen' do
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
    let(:config_file_name) { config_old_format_socket }

    before do
      clear_pool
    end
    after do
      clear_pool
    end

    context 'when running on single-threaded runtime' do
      before do
        allow(Gitlab::Runtime).to receive(:multi_threaded?).and_return(false)
      end

      it 'instantiates a connection pool with size 5' do
        expect(ConnectionPool).to receive(:new).with(size: 5).and_call_original

        described_class.with { |_redis_shared_example| true }
      end
    end

    context 'when running on multi-threaded runtime' do
      before do
        allow(Gitlab::Runtime).to receive(:multi_threaded?).and_return(true)
        allow(Gitlab::Runtime).to receive(:max_threads).and_return(18)
      end

      it 'instantiates a connection pool with a size based on the concurrency of the worker' do
        expect(ConnectionPool).to receive(:new).with(size: 18 + 5).and_call_original

        described_class.with { |_redis_shared_example| true }
      end
    end

    context 'when there is no config at all' do
      before do
        # Undo top-level stub of config_file_name because we are testing that method now.
        allow(described_class).to receive(:config_file_name).and_call_original

        allow(described_class).to receive(:rails_root).and_return(rails_root)
      end

      after do
        FileUtils.rm_rf(rails_root)
      end

      it 'can run an empty block' do
        expect { described_class.with { nil } }.not_to raise_error
      end
    end
  end

  describe '#sentinels' do
    subject { described_class.new(rails_env).sentinels }

    let(:rails_env) { 'development' }

    context 'when sentinels are defined' do
      let(:config_file_name) { config_new_format_host }

      where(:rails_env, :hosts) do
        [
          ['development', %w[development-replica1 development-replica2]],
          ['test', %w[test-replica1 test-replica2]],
          ['production', %w[production-replica1 production-replica2]]
        ]
      end

      with_them do
        it 'returns an array of hashes with host and port keys' do
          is_expected.to include(host: hosts[0], port: sentinel_port)
          is_expected.to include(host: hosts[1], port: sentinel_port)
        end
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
