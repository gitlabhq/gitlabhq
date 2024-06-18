# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/mark_used_feature_flags'

RSpec.describe RuboCop::Cop::Gitlab::MarkUsedFeatureFlags do
  let(:defined_feature_flags) do
    %w[a_feature_flag foo_hello foo_world bar_baz baz]
  end

  before do
    allow(cop).to receive(:defined_feature_flags).and_return(defined_feature_flags)
    allow(cop).to receive(:usage_data_counters_known_event_feature_flags).and_return([])
    described_class.feature_flags_already_tracked = false
  end

  def feature_flag_path(feature_flag_name)
    File.expand_path("../../../../tmp/feature_flags/#{feature_flag_name}.used", __dir__)
  end

  shared_examples 'sets flag as used' do |method_call, flags_to_be_set|
    it 'sets the flag as used' do
      Array(flags_to_be_set).each do |flag_to_be_set|
        expect(FileUtils).to receive(:touch).with(feature_flag_path(flag_to_be_set))
      end

      expect_no_offenses(<<~RUBY)
        class Foo < ApplicationRecord
          #{method_call}
        end
      RUBY
    end
  end

  shared_examples 'does not set any flags as used' do |method_call|
    it 'sets the flag as used' do
      expect(FileUtils).not_to receive(:touch)

      expect_no_offenses(method_call)
    end
  end

  %w[
    Feature.enabled?
    Feature.disabled?
    push_frontend_feature_flag
    Config::FeatureFlags.enabled?
    ::Gitlab::Ci::Config::FeatureFlags.enabled?
  ].each do |feature_flag_method|
    context "#{feature_flag_method} method" do
      context 'a string feature flag' do
        include_examples 'sets flag as used', %|#{feature_flag_method}("foo")|, 'foo'
      end

      context 'a symbol feature flag' do
        include_examples 'sets flag as used', %|#{feature_flag_method}(:foo)|, 'foo'
      end

      context 'an interpolated string feature flag with a string prefix' do
        include_examples 'sets flag as used', %|#{feature_flag_method}("foo_\#{bar}")|, %w[foo_hello foo_world]
      end

      context 'an interpolated symbol feature flag with a string prefix' do
        include_examples 'sets flag as used', %|#{feature_flag_method}(:"foo_\#{bar}")|, %w[foo_hello foo_world]
      end

      context 'a string with a "/" in it' do
        include_examples 'sets flag as used', %|#{feature_flag_method}("bar/baz")|, 'bar_baz'
      end

      context 'an interpolated string feature flag with a string prefix and suffix' do
        include_examples 'does not set any flags as used', %|#{feature_flag_method}(:"foo_\#{bar}_baz")|
      end

      context 'a dynamic string feature flag as a variable' do
        include_examples 'does not set any flags as used', %|#{feature_flag_method}(a_variable, an_arg)|
      end

      context 'an integer feature flag' do
        include_examples 'does not set any flags as used', %|#{feature_flag_method}(123)|
      end
    end
  end

  %w[
    Feature::Gitaly.enabled?
    Feature::Gitaly.disabled?
  ].each do |feature_flag_method|
    context "#{feature_flag_method} method" do
      context 'a string feature flag' do
        include_examples 'sets flag as used', %|#{feature_flag_method}("foo")|, 'gitaly_foo'
      end

      context 'a symbol feature flag' do
        include_examples 'sets flag as used', %|#{feature_flag_method}(:foo)|, 'gitaly_foo'
      end

      context 'an interpolated string feature flag with a string prefix' do
        include_examples 'sets flag as used', %|#{feature_flag_method}("foo_\#{bar}")|, %w[foo_hello foo_world]
      end

      context 'an interpolated symbol feature flag with a string prefix' do
        include_examples 'sets flag as used', %|#{feature_flag_method}(:"foo_\#{bar}")|, %w[foo_hello foo_world]
      end

      context 'an interpolated string feature flag with a string prefix and suffix' do
        include_examples 'does not set any flags as used', %|#{feature_flag_method}(:"foo_\#{bar}_baz")|
      end

      context 'a dynamic string feature flag as a variable' do
        include_examples 'does not set any flags as used', %|#{feature_flag_method}(a_variable, an_arg)|
      end

      context 'an integer feature flag' do
        include_examples 'does not set any flags as used', %|#{feature_flag_method}(123)|
      end
    end
  end

  context 'with the experiment method' do
    context 'a string feature flag' do
      include_examples 'sets flag as used', %q|experiment("baz")|, %w[baz]
    end

    context 'a symbol feature flag' do
      include_examples 'sets flag as used', %q|experiment(:baz)|, %w[baz]
    end

    context 'an interpolated string feature flag with a string prefix' do
      include_examples 'sets flag as used', %|experiment("foo_\#{bar}")|, %w[foo_hello foo_world]
    end

    context 'an interpolated symbol feature flag with a string prefix' do
      include_examples 'sets flag as used', %|experiment(:"foo_\#{bar}")|, %w[foo_hello foo_world]
    end

    context 'an interpolated string feature flag with a string prefix and suffix' do
      include_examples 'does not set any flags as used', %|experiment(:"foo_\#{bar}_baz")|
    end

    context 'a dynamic string feature flag as a variable' do
      include_examples 'does not set any flags as used', %q|experiment(a_variable, an_arg)|
    end

    context 'an integer feature flag' do
      include_examples 'does not set any flags as used', %q|experiment(123)|
    end
  end

  describe 'self.limit_feature_flag = :foo' do
    include_examples 'sets flag as used', 'self.limit_feature_flag = :foo', 'foo'
  end

  describe 'self.limit_feature_flag_for_override = :foo' do
    include_examples 'sets flag as used', 'self.limit_feature_flag_for_override = :foo', 'foo'
  end

  describe 'FEATURE_FLAG = :foo' do
    include_examples 'sets flag as used', 'FEATURE_FLAG = :foo', 'foo'
  end

  describe 'ROUTING_FEATURE_FLAG = :foo' do
    include_examples 'sets flag as used', 'ROUTING_FEATURE_FLAG = :foo', 'foo'
  end

  describe 'Worker `data_consistency` method' do
    include_examples 'sets flag as used', 'data_consistency :delayed, feature_flag: :foo', 'foo'
    include_examples 'does not set any flags as used', 'data_consistency :delayed'
  end

  describe 'Class with included WorkerAttributes `data_consistency` method' do
    include_examples 'sets flag as used', 'ActionMailer::MailDeliveryJob.data_consistency :delayed, feature_flag: :foo', 'foo'
    include_examples 'does not set any flags as used', 'data_consistency :delayed'
  end

  describe 'Worker `deduplicate` method' do
    include_examples 'sets flag as used', 'deduplicate :delayed, feature_flag: :foo', 'foo'
    include_examples 'does not set any flags as used', 'deduplicate :delayed'
  end
end
