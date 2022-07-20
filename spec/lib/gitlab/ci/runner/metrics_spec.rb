# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Runner::Metrics, :prometheus do
  subject { described_class.new }

  describe '#increment_runner_authentication_success_counter' do
    it 'increments count for same type' do
      expect { subject.increment_runner_authentication_success_counter(runner_type: 'instance_type') }
        .to change { described_class.runner_authentication_success_counter.get(runner_type: 'instance_type') }.by(1)
    end

    it 'does not increment count for different type' do
      expect { subject.increment_runner_authentication_success_counter(runner_type: 'group_type') }
        .to not_change { described_class.runner_authentication_success_counter.get(runner_type: 'project_type') }
    end

    it 'does not increment failure count' do
      expect { subject.increment_runner_authentication_success_counter(runner_type: 'project_type') }
        .to not_change { described_class.runner_authentication_failure_counter.get }
    end

    it 'throws ArgumentError for invalid runner type' do
      expect { subject.increment_runner_authentication_success_counter(runner_type: 'unknown_type') }
        .to raise_error(ArgumentError, 'unknown runner type: unknown_type')
    end
  end

  describe '#increment_runner_authentication_failure_counter' do
    it 'increments count' do
      expect { subject.increment_runner_authentication_failure_counter }
        .to change { described_class.runner_authentication_failure_counter.get }.by(1)
    end

    it 'does not increment success count' do
      expect { subject.increment_runner_authentication_failure_counter }
        .to not_change { described_class.runner_authentication_success_counter.get(runner_type: 'instance_type') }
    end
  end
end
