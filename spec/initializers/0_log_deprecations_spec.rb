# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '0_log_deprecations' do
  def setup_other_deprecations
    Warning.process(__FILE__) { :default }
  end

  def load_initializer
    load Rails.root.join('config/initializers/0_log_deprecations.rb')
  end

  def with_deprecation_behavior
    behavior = ActiveSupport::Deprecation.behavior
    ActiveSupport::Deprecation.behavior = deprecation_behavior
    yield
  ensure
    ActiveSupport::Deprecation.behavior = behavior
  end

  let(:deprecation_behavior) { :stderr }
  let(:env_var) { '1' }

  before do
    stub_env('GITLAB_LOG_DEPRECATIONS', env_var)
    setup_other_deprecations
    load_initializer
  end

  after do
    ActiveSupport::Notifications.unsubscribe('deprecation.rails')
  end

  around do |example|
    with_deprecation_behavior do
      # reset state changed by initializer
      Warning.clear(&example)
    end
  end

  describe 'Ruby deprecations' do
    shared_examples 'deprecation logger' do
      it 'logs them to deprecation logger once and to stderr' do
        expect(Gitlab::DeprecationJsonLogger).to receive(:info).with(
          message: 'ABC gem is deprecated',
          source: 'ruby'
        )

        expect { subject }.to output.to_stderr
      end
    end

    context 'when catching deprecations through Kernel#warn' do
      subject { warn('ABC gem is deprecated') }

      include_examples 'deprecation logger'

      context 'with non-notify deprecation behavior' do
        let(:deprecation_behavior) { :silence }

        include_examples 'deprecation logger'
      end

      context 'with notify deprecation behavior' do
        let(:deprecation_behavior) { :notify }

        include_examples 'deprecation logger'
      end
    end

    describe 'other messages from Kernel#warn' do
      it 'does not log them to deprecation logger' do
        expect(Gitlab::DeprecationJsonLogger).not_to receive(:info)

        expect { warn('Sure is hot today') }.to output.to_stderr
      end
    end

    context 'when disabled via environment' do
      let(:env_var) { '0' }

      it 'does not log them to deprecation logger' do
        expect(Gitlab::DeprecationJsonLogger).not_to receive(:info)

        expect { warn('ABC gem is deprecated') }.to output.to_stderr
      end
    end
  end

  describe 'Rails deprecations' do
    subject { ActiveSupport::Deprecation.warn('ABC will be removed') }

    shared_examples 'deprecation logger' do
      it 'logs them to deprecation logger once' do
        expect(Gitlab::DeprecationJsonLogger).to receive(:info).with(
          message: match(/^DEPRECATION WARNING: ABC will be removed/),
          source: 'rails'
        )

        subject
      end
    end

    context 'with non-notify deprecation behavior' do
      let(:deprecation_behavior) { :silence }

      include_examples 'deprecation logger'
    end

    context 'with notify deprecation behavior' do
      let(:deprecation_behavior) { :notify }

      include_examples 'deprecation logger'
    end

    context 'when deprecations were silenced' do
      around do |example|
        silenced = ActiveSupport::Deprecation.silenced
        ActiveSupport::Deprecation.silenced = true
        example.run
        ActiveSupport::Deprecation.silenced = silenced
      end

      include_examples 'deprecation logger'
    end

    context 'when disabled via environment' do
      let(:env_var) { '0' }

      it 'does not log them to deprecation logger' do
        expect(Gitlab::DeprecationJsonLogger).not_to receive(:info)

        expect { ActiveSupport::Deprecation.warn('ABC will be removed') }.to output.to_stderr
      end
    end
  end
end
