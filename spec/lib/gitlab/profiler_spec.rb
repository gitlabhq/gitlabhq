# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Profiler do
  let(:null_logger) { Logger.new('/dev/null') }
  let(:private_token) { 'private' }

  describe '.profile' do
    let(:app) { double(:app) }

    before do
      allow(ActionDispatch::Integration::Session).to receive(:new).and_return(app)
      allow(app).to receive(:get)
    end

    it 'returns a profile result' do
      expect(described_class.profile('/')).to be_an_instance_of(RubyProf::Profile)
    end

    it 'uses the custom logger given' do
      expect(described_class).to receive(:create_custom_logger)
                                   .with(null_logger, private_token: anything)
                                   .and_call_original

      described_class.profile('/', logger: null_logger)
    end

    it 'sends a POST request when data is passed' do
      post_data = '{"a":1}'

      expect(app).to receive(:post).with(anything, params: post_data, headers: anything)

      described_class.profile('/', post_data: post_data)
    end

    it 'uses the private_token for auth if given' do
      expect(app).to receive(:get).with('/', params: nil, headers: { 'Private-Token' => private_token })
      expect(app).to receive(:get).with('/api/v4/users')

      described_class.profile('/', private_token: private_token)
    end

    it 'uses the user for auth if given' do
      user = double(:user)

      expect(described_class).to receive(:with_user).with(user)

      described_class.profile('/', user: user)
    end

    it 'uses the private_token for auth if both it and user are set' do
      user = double(:user)

      expect(described_class).to receive(:with_user).with(nil).and_call_original
      expect(app).to receive(:get).with('/', params: nil, headers: { 'Private-Token' => private_token })
      expect(app).to receive(:get).with('/api/v4/users')

      described_class.profile('/', user: user, private_token: private_token)
    end
  end

  describe '.create_custom_logger' do
    it 'does nothing when nil is passed' do
      expect(described_class.create_custom_logger(nil)).to be_nil
    end

    context 'the new logger' do
      let(:custom_logger) do
        described_class.create_custom_logger(null_logger, private_token: private_token)
      end

      it 'does not affect the existing logger' do
        expect(null_logger).not_to receive(:debug)
        expect(custom_logger).to receive(:debug).and_call_original

        custom_logger.debug('Foo')
      end

      it 'strips out the private token' do
        allow(custom_logger).to receive(:add).and_call_original
        expect(custom_logger).to receive(:add).with(Logger::DEBUG, anything, 'public [FILTERED]').at_least(1)

        custom_logger.debug("public #{private_token}")
      end

      it 'tracks model load times by model' do
        custom_logger.debug('This is not a model load')
        custom_logger.debug('User Load (1.2ms)')
        custom_logger.debug('User Load (1.3ms)')
        custom_logger.debug('Project Load (10.4ms)')

        expect(custom_logger.load_times_by_model).to eq('User' => [1.2, 1.3],
                                                        'Project' => [10.4])
      end

      it 'logs the backtrace, ignoring lines as appropriate' do
        # Skip Rails's backtrace cleaning.
        allow(Rails.backtrace_cleaner).to receive(:clean, &:itself)

        expect(custom_logger).to receive(:add)
                                   .with(Logger::DEBUG,
                                         anything,
                                         a_string_matching(File.basename(__FILE__)))
                                   .twice

        expect(custom_logger).not_to receive(:add).with(Logger::DEBUG,
                                                        anything,
                                                        a_string_matching('lib/gitlab/profiler.rb'))

        # Force a part of the backtrace to be in the (ignored) profiler source
        # file.
        described_class.with_custom_logger(nil) { custom_logger.debug('Foo') }
      end
    end
  end

  describe '.with_custom_logger' do
    context 'when the logger is set' do
      it 'uses the replacement logger for the duration of the block' do
        expect(null_logger).to receive(:debug).and_call_original

        expect { described_class.with_custom_logger(null_logger) { ActiveRecord::Base.logger.debug('foo') } }
          .to not_change { ActiveRecord::Base.logger }
          .and not_change { ActionController::Base.logger }
          .and not_change { ActiveSupport::LogSubscriber.colorize_logging }
      end

      it 'returns the result of the block' do
        expect(described_class.with_custom_logger(null_logger) { 2 }).to eq(2)
      end
    end

    context 'when the logger is nil' do
      it 'returns the result of the block' do
        expect(described_class.with_custom_logger(nil) { 2 }).to eq(2)
      end

      it 'does not modify the standard Rails loggers' do
        expect { described_class.with_custom_logger(nil) {} }
          .to not_change { ActiveRecord::Base.logger }
          .and not_change { ActionController::Base.logger }
          .and not_change { ActiveSupport::LogSubscriber.colorize_logging }
      end
    end
  end

  describe '.with_user' do
    context 'when the user is set' do
      let(:user) { double(:user) }

      it 'overrides auth in ApplicationController to use the given user' do
        expect(described_class.with_user(user) { ApplicationController.new.current_user }).to eq(user)
      end

      it 'cleans up ApplicationController afterwards' do
        expect { described_class.with_user(user) {} }
          .to not_change { ActionController.instance_methods(false) }
      end
    end

    context 'when the user is nil' do
      it 'does not define methods on ApplicationController' do
        expect(ApplicationController).not_to receive(:define_method)

        described_class.with_user(nil) {}
      end
    end
  end

  describe '.log_load_times_by_model' do
    it 'logs the model, query count, and time by slowest first' do
      expect(null_logger).to receive(:load_times_by_model).and_return(
        'User' => [1.2, 1.3],
        'Project' => [10.4]
      )

      expect(null_logger).to receive(:info).with('Project total (1): 10.4ms')
      expect(null_logger).to receive(:info).with('User total (2): 2.5ms')

      described_class.log_load_times_by_model(null_logger)
    end

    it 'does nothing when called with a logger that does not have load times' do
      expect(null_logger).not_to receive(:info)

      expect(described_class.log_load_times_by_model(null_logger)).to be_nil
    end
  end

  describe '.print_by_total_time' do
    let(:stdout) { StringIO.new }
    let(:regexp) { /^\s+\d+\.\d+\s+(\d+\.\d+)/ }

    let(:output) do
      stdout.rewind
      stdout.read
    end

    let_it_be(:result) do
      Thread.new { sleep 1 }

      RubyProf.profile do
        sleep 0.1
        1.to_s
      end
    end

    around do |example|
      original_stdout = $stdout

      $stdout = stdout # rubocop: disable RSpec/ExpectOutput
      example.run
      $stdout = original_stdout # rubocop: disable RSpec/ExpectOutput
    end

    it 'prints a profile result sorted by total time' do
      described_class.print_by_total_time(result)

      expect(output).to include('Kernel#sleep')

      thread_profiles = output.split('Sort by: total_time').select { |x| x =~ regexp }

      thread_profiles.each do |profile|
        total_times =
          profile
            .scan(regexp)
            .map { |(total)| total.to_f }

        expect(total_times).to eq(total_times.sort.reverse)
      end
    end

    it 'accepts a max_percent option' do
      described_class.print_by_total_time(result, max_percent: 50)

      expect(output).not_to include('Kernel#sleep')
    end
  end
end
