# frozen_string_literal: true
require 'spec_helper'
require_relative './simple_check_shared'

RSpec.describe Gitlab::HealthChecks::Redis do
  describe "ALL_INSTANCE_CHECKS" do
    subject { described_class::ALL_INSTANCE_CHECKS }

    it { is_expected.to include(described_class::CacheCheck, described_class::QueuesCheck) }

    it "contains a check for each redis instance" do
      expect(subject.map(&:redis_instance_class_name)).to contain_exactly(*Gitlab::Redis::ALL_CLASSES)
    end
  end

  describe 'all checks' do
    described_class::ALL_INSTANCE_CHECKS.each do |check|
      describe check do
        include_examples 'simple_check',
          "redis_#{check.redis_instance_class_name.store_name.underscore}_ping",
          check.redis_instance_class_name.store_name,
          'PONG'
      end
    end
  end
end
