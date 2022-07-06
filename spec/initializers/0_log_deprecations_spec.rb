# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '0_log_deprecations' do
  def setup_other_deprecations
    Warning.process(__FILE__) { :raise }
  end

  def load_initializer
    load Rails.root.join('config/initializers/0_log_deprecations.rb')
  end

  let(:env_var) { '1' }

  before do
    stub_env('GITLAB_LOG_DEPRECATIONS', env_var)
    setup_other_deprecations
    load_initializer
  end

  after do
    # reset state changed by initializer
    Warning.clear
    ActiveSupport::Notifications.unsubscribe('deprecation.rails')
  end

  describe 'Ruby deprecations' do
    context 'when catching deprecations through Kernel#warn' do
      it 'also logs them to deprecation logger' do
        expect(Gitlab::DeprecationJsonLogger).to receive(:info).with(
          message: 'ABC gem is deprecated',
          source: 'ruby'
        )

        expect { warn('ABC gem is deprecated') }.to output.to_stderr
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
    it 'logs them to deprecation logger' do
      expect(Gitlab::DeprecationJsonLogger).to receive(:info).with(
        message: match(/^DEPRECATION WARNING: ABC will be removed/),
        source: 'rails'
      )

      expect { ActiveSupport::Deprecation.warn('ABC will be removed') }.to output.to_stderr
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
