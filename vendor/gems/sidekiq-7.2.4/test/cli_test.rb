# frozen_string_literal: true

require_relative "helper"
require "sidekiq/cli"

describe Sidekiq::CLI do
  before do
    ENV["RAILS_ENV"] = ENV["RACK_ENV"] = ENV["APP_ENV"] = nil
    @logdev = StringIO.new
    @config = reset!
    @config.logger = Logger.new(@logdev)
    @cli = Sidekiq::CLI.new.tap { |c| c.config = config }
  end

  attr_reader :config
  attr_reader :logdev

  def queues
    @cli.config.queues
  end

  def concurrency
    @cli.config.concurrency
  end

  def capsules
    @cli.config.capsules
  end

  describe "#parse" do
    describe "options" do
      it "accepts -r" do
        @cli.parse(%w[sidekiq -r ./test/fake_env.rb])
        assert_equal "./test/fake_env.rb", config[:require]
      end

      describe "concurrency" do
        it "accepts with -c" do
          @cli.parse(%w[sidekiq -c 60 -r ./test/fake_env.rb])

          assert_equal 60, concurrency
        end

        describe "when concurrency is empty and RAILS_MAX_THREADS env var is set" do
          before do
            ENV["RAILS_MAX_THREADS"] = "9"
          end

          after do
            ENV.delete("RAILS_MAX_THREADS")
          end

          it "sets concurrency from RAILS_MAX_THREADS env var" do
            @cli.parse(%w[sidekiq -r ./test/fake_env.rb])

            assert_equal 9, concurrency
          end

          it "option overrides RAILS_MAX_THREADS env var" do
            @cli.parse(%w[sidekiq -c 60 -r ./test/fake_env.rb])

            assert_equal 60, concurrency
          end
        end
      end

      describe "queues" do
        it "accepts with -q" do
          @cli.parse(%w[sidekiq -q foo -r ./test/fake_env.rb])

          assert_equal ["foo"], queues
        end

        describe "when weights are not present" do
          it "accepts queues without weights" do
            @cli.parse(%w[sidekiq -q foo -q bar -r ./test/fake_env.rb])

            assert_equal ["foo", "bar"], queues
          end
        end

        describe "when weights are present" do
          it "accepts queues with weights" do
            @cli.parse(%w[sidekiq -q foo,3 -q bar -r ./test/fake_env.rb])

            assert_equal ["foo", "foo", "foo", "bar"], queues
          end
        end

        it "accepts queues with multi-word names" do
          @cli.parse(%w[sidekiq -q queue_one -q queue-two -r ./test/fake_env.rb])

          assert_equal ["queue_one", "queue-two"], queues
        end

        it "accepts queues with dots in the name" do
          @cli.parse(%w[sidekiq -q foo.bar -r ./test/fake_env.rb])

          assert_equal ["foo.bar"], queues
        end

        describe "when queues are empty" do
          describe "when no queues are specified via -q" do
            it "sets 'default' queue" do
              @cli.parse(%w[sidekiq -r ./test/fake_env.rb])

              assert_equal ["default"], queues
            end
          end

          describe "when no queues are specified via the config file" do
            it "sets 'default' queue" do
              @cli.parse(%w[sidekiq -C ./test/cfg/config_empty.yml -r ./test/fake_env.rb])

              assert_equal ["default"], queues
            end
          end
        end
      end

      describe "timeout" do
        it "accepts with -t" do
          @cli.parse(%w[sidekiq -t 30 -r ./test/fake_env.rb])

          assert_equal 30, config[:timeout]
        end
      end

      describe "verbose" do
        it "accepts with -v" do
          @cli.parse(%w[sidekiq -v -r ./test/fake_env.rb])

          assert_equal Logger::DEBUG, @config.logger.level
        end
      end

      describe "environmental" do
        it "handles RAILS_ENV" do
          ENV["RAILS_ENV"] = "xyzzy"
          @cli.parse(%w[sidekiq -C ./test/config.yml])
          assert_equal "xyzzy", config[:environment]
        ensure
          ENV.delete "RAILS_ENV"
        end
      end

      describe "config file" do
        it "accepts with -C" do
          @cli.parse(%w[sidekiq -C ./test/config.yml])

          assert_equal "./test/config.yml", config[:config_file]
          refute config[:verbose]
          assert_equal "./test/fake_env.rb", config[:require]
          assert_equal "development", config[:environment]
          assert_equal 50, concurrency
          assert_equal 2, queues.count { |q| q == "very_often" }
          assert_equal 1, queues.count { |q| q == "seldom" }
        end

        it "accepts stringy keys" do
          @cli.parse(%w[sidekiq -C ./test/cfg/config_string.yml])

          assert_equal "./test/cfg/config_string.yml", config[:config_file]
          refute config[:verbose]
          assert_equal "./test/fake_env.rb", config[:require]
          assert_equal "development", config[:environment]
          assert_equal 50, concurrency
          assert_equal 2, queues.count { |q| q == "very_often" }
          assert_equal 1, queues.count { |q| q == "seldom" }
        end

        it "accepts environment specific config" do
          @cli.parse(%w[sidekiq -e staging -C ./test/cfg/config_environment.yml])

          assert_equal "./test/cfg/config_environment.yml", config[:config_file]
          refute config[:verbose]
          assert_equal "./test/fake_env.rb", config[:require]
          assert_equal "staging", config[:environment]
          assert_equal 50, concurrency
          assert_equal 2, queues.count { |q| q == "very_often" }
          assert_equal 1, queues.count { |q| q == "seldom" }
        end

        it "accepts environment specific config with alias" do
          @cli.parse(%w[sidekiq -e staging -C ./test/cfg/config_with_alias.yml])
          assert_equal "./test/cfg/config_with_alias.yml", config[:config_file]
          refute config[:verbose]
          assert_equal "./test/fake_env.rb", config[:require]
          assert_equal "staging", config[:environment]
          assert_equal 50, concurrency
          assert_equal 2, queues.count { |q| q == "very_often" }
          assert_equal 1, queues.count { |q| q == "seldom" }

          @cli.parse(%w[sidekiq -e production -C ./test/cfg/config_with_alias.yml])
          assert_equal "./test/cfg/config_with_alias.yml", config[:config_file]
          assert config[:verbose]
          assert_equal "./test/fake_env.rb", config[:require]
          assert_equal "production", config[:environment]
          assert_equal 50, concurrency
          assert_equal 2, queues.count { |q| q == "very_often" }
          assert_equal 1, queues.count { |q| q == "seldom" }
        end

        it "exposes ERB expected __FILE__ and __dir__" do
          given_path = "./test/cfg/config__FILE__and__dir__.yml"
          expected_file = File.expand_path(given_path)
          # As per Ruby's Kernel module docs, __dir__ is equivalent to File.dirname(File.realpath(__FILE__))
          expected_dir = File.dirname(File.realpath(expected_file))

          @cli.parse(%W[sidekiq -C #{given_path}])

          assert_equal(expected_file, config.fetch(:__FILE__))
          assert_equal(expected_dir, config.fetch(:__dir__))
        end

        it "configures capsules defined in the config file" do
          @cli.parse(%w[sidekiq -C ./test/cfg/config_capsules.yml])
          assert_equal 1, capsules["non_concurrent"].concurrency
          assert_equal %w[non_concurrent], capsules["non_concurrent"].queues

          assert_equal 2, capsules["binary"].concurrency
          assert_equal %w[sirius sirius_b], capsules["binary"].queues
        end
      end

      describe "default config file" do
        describe "when required path is a directory" do
          it "tries config/sidekiq.yml from required directory" do
            @cli.parse(%w[sidekiq -r ./test/dummy])

            assert_equal "./test/dummy/config/sidekiq.yml", config[:config_file]
            assert_equal 25, concurrency
          end
        end

        describe "when required path is a file" do
          it "tries config/sidekiq.yml from current directory" do
            config[:require] = "./test/dummy" # stub current dir – ./

            @cli.parse(%w[sidekiq -r ./test/fake_env.rb])

            assert_equal "./test/dummy/config/sidekiq.yml", config[:config_file]
            assert_equal 25, concurrency
          end
        end

        describe "without any required path" do
          it "tries config/sidekiq.yml from current directory" do
            config[:require] = "./test/dummy" # stub current dir – ./

            @cli.parse(%w[sidekiq])

            assert_equal "./test/dummy/config/sidekiq.yml", config[:config_file]
            assert_equal 25, concurrency
          end
        end

        describe "when config file and flags" do
          it "merges options" do
            @cli.parse(%w[sidekiq -C ./test/config.yml
              -e snoop
              -c 100
              -r ./test/fake_env.rb
              -q often,7
              -q seldom,3])

            assert_equal "./test/config.yml", config[:config_file]
            refute config[:verbose]
            assert_equal "./test/fake_env.rb", config[:require]
            assert_equal "snoop", config[:environment]
            assert_equal 100, concurrency
            assert_equal 7, queues.count { |q| q == "often" }
            assert_equal 3, queues.count { |q| q == "seldom" }
          end
        end

        describe "default config file" do
          describe "when required path is a directory" do
            it "tries config/sidekiq.yml" do
              @cli.parse(%w[sidekiq -r ./test/dummy])

              assert_equal "sidekiq.yml", File.basename(config[:config_file])
              assert_equal 25, concurrency
            end
          end
        end
      end
    end

    describe "validation" do
      describe "when required application path does not exist" do
        it "exits with status 1" do
          exit = assert_raises(SystemExit) { @cli.parse(%w[sidekiq -r /non/existent/path]) }
          assert_equal 1, exit.status
        end
      end

      describe "when required path is a directory without config/application.rb" do
        it "exits with status 1" do
          exit = assert_raises(SystemExit) { @cli.parse(%w[sidekiq -r ./test/fixtures]) }
          assert_equal 1, exit.status
        end

        describe "when config file path does not exist" do
          it "raises argument error" do
            assert_raises(ArgumentError) do
              @cli.parse(%w[sidekiq -r ./test/fake_env.rb -C /non/existent/path])
            end
          end
        end
      end

      describe "when concurrency is not valid" do
        describe "when set to 0" do
          it "raises argument error" do
            assert_raises(ArgumentError) do
              @cli.parse(%w[sidekiq -r ./test/fake_env.rb -c 0])
            end
          end
        end

        describe "when set to a negative number" do
          it "raises argument error" do
            assert_raises(ArgumentError) do
              @cli.parse(%w[sidekiq -r ./test/fake_env.rb -c -2])
            end
          end
        end
      end

      describe "when timeout is not valid" do
        describe "when set to 0" do
          it "raises argument error" do
            assert_raises(ArgumentError) do
              @cli.parse(%w[sidekiq -r ./test/fake_env.rb -t 0])
            end
          end
        end

        describe "when set to a negative number" do
          it "raises argument error" do
            assert_raises(ArgumentError) do
              @cli.parse(%w[sidekiq -r ./test/fake_env.rb -t -2])
            end
          end
        end
      end
    end

    describe "#run" do
      before do
        @cli.config[:require] = "./test/fake_env.rb"
      end

      describe "require workers" do
        describe "when path is a rails directory" do
          before do
            @cli.config[:require] = "./test/dummy"
            @cli.environment = "test"
          end

          it "requires sidekiq railtie and rails application with environment" do
            @cli.stub(:launch, nil) do
              @cli.run
            end

            assert defined?(Sidekiq::Rails)
            assert defined?(Dummy::Application)
          end

          it "tags with the app directory name" do
            @cli.stub(:launch, nil) do
              @cli.run
            end

            assert_equal "dummy", @cli.config[:tag]
          end
        end

        describe "when path is file" do
          it "requires application" do
            @cli.stub(:launch, nil) do
              @cli.run
            end

            assert $LOADED_FEATURES.any? { |x| x =~ /test\/fake_env/ }
          end
        end
      end

      describe "checking maxmemory policy" do
        it "warns if the policy is not noeviction" do
          redis_info = {"maxmemory_policy" => "allkeys-lru", "redis_version" => "6.2.1"}

          @cli.config.stub(:redis_info, redis_info) do
            @cli.stub(:launch, nil) do
              @cli.run
            end
          end

          assert_includes @logdev.string, "allkeys-lru"
        end

        it "silent if the policy is noeviction" do
          redis_info = {"maxmemory_policy" => "noeviction", "redis_version" => "6.2.1"}

          @cli.config.stub(:redis_info, redis_info) do
            @cli.stub(:launch, nil) do
              @cli.run
            end
          end

          refute_includes @logdev.string, "noeviction"
        end
      end
    end

    describe "signal handling" do
      %w[INT TERM].each do |sig|
        describe sig do
          it "raises interrupt error" do
            assert_raises Interrupt do
              @cli.handle_signal(sig)
            end
          end
        end
      end

      describe "TSTP" do
        it "quiets with a corresponding event" do
          quiet = false

          @cli.config.on(:quiet) do
            quiet = true
          end

          @cli.launcher = Sidekiq::Launcher.new(@cli.config)
          @cli.handle_signal("TSTP")

          assert_match(/Got TSTP signal/, logdev.string)
          assert_equal true, quiet
        end
      end

      describe "TTIN" do
        it "prints backtraces for all threads in the process to the logfile" do
          @cli.handle_signal("TTIN")

          assert_match(/Got TTIN signal/, logdev.string)
          assert_match(/\bbacktrace\b/, logdev.string)
        end
      end

      describe "UNKNOWN" do
        it "logs about" do
          # @cli.parse(%w[sidekiq -r ./test/fake_env.rb])
          @cli.handle_signal("UNKNOWN")

          assert_match(/Got UNKNOWN signal/, logdev.string)
          assert_match(/No signal handler registered/, logdev.string)
        end
      end
    end
  end
end
