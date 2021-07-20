# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/gitlab/mark_used_feature_flags'

RSpec.describe RuboCop::Cop::Gitlab::MarkUsedFeatureFlags do
  let(:defined_feature_flags) do
    %w[a_feature_flag foo_hello foo_world baz_experiment_percentage bar_baz]
  end

  subject(:cop) { described_class.new }

  before do
    stub_const("#{described_class}::DYNAMIC_FEATURE_FLAGS", [])
    allow(cop).to receive(:defined_feature_flags).and_return(defined_feature_flags)
    allow(cop).to receive(:usage_data_counters_known_event_feature_flags).and_return([])
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
  ].each do |feature_flag_method|
    context "#{feature_flag_method} method" do
      context 'a string feature flag' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}("foo")|, 'foo'
      end

      context 'a symbol feature flag' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}(:foo)|, 'foo'
      end

      context 'an interpolated string feature flag with a string prefix' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}("foo_\#{bar}")|, %w[foo_hello foo_world]
      end

      context 'an interpolated symbol feature flag with a string prefix' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}(:"foo_\#{bar}")|, %w[foo_hello foo_world]
      end

      context 'a string with a "/" in it' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}("bar/baz")|, 'bar_baz'
      end

      context 'an interpolated string feature flag with a string prefix and suffix' do
        include_examples 'does not set any flags as used', %Q|#{feature_flag_method}(:"foo_\#{bar}_baz")|
      end

      context 'a dynamic string feature flag as a variable' do
        include_examples 'does not set any flags as used', %Q|#{feature_flag_method}(a_variable, an_arg)|
      end

      context 'an integer feature flag' do
        include_examples 'does not set any flags as used', %Q|#{feature_flag_method}(123)|
      end
    end
  end

  %w[
    Feature::Gitaly.enabled?
    Feature::Gitaly.disabled?
  ].each do |feature_flag_method|
    context "#{feature_flag_method} method" do
      context 'a string feature flag' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}("foo")|, 'gitaly_foo'
      end

      context 'a symbol feature flag' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}(:foo)|, 'gitaly_foo'
      end

      context 'an interpolated string feature flag with a string prefix' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}("foo_\#{bar}")|, %w[foo_hello foo_world]
      end

      context 'an interpolated symbol feature flag with a string prefix' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}(:"foo_\#{bar}")|, %w[foo_hello foo_world]
      end

      context 'an interpolated string feature flag with a string prefix and suffix' do
        include_examples 'does not set any flags as used', %Q|#{feature_flag_method}(:"foo_\#{bar}_baz")|
      end

      context 'a dynamic string feature flag as a variable' do
        include_examples 'does not set any flags as used', %Q|#{feature_flag_method}(a_variable, an_arg)|
      end

      context 'an integer feature flag' do
        include_examples 'does not set any flags as used', %Q|#{feature_flag_method}(123)|
      end
    end
  end

  %w[
    experiment
    experiment_enabled?
    push_frontend_experiment
    Gitlab::Experimentation.active?
  ].each do |feature_flag_method|
    context "#{feature_flag_method} method" do
      context 'a string feature flag' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}("baz")|, %w[baz baz_experiment_percentage]
      end

      context 'a symbol feature flag' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}(:baz)|, %w[baz baz_experiment_percentage]
      end

      context 'an interpolated string feature flag with a string prefix' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}("foo_\#{bar}")|, %w[foo_hello foo_world]
      end

      context 'an interpolated symbol feature flag with a string prefix' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}(:"foo_\#{bar}")|, %w[foo_hello foo_world]
      end

      context 'an interpolated string feature flag with a string prefix and suffix' do
        include_examples 'does not set any flags as used', %Q|#{feature_flag_method}(:"foo_\#{bar}_baz")|
      end

      context 'a dynamic string feature flag as a variable' do
        include_examples 'does not set any flags as used', %Q|#{feature_flag_method}(a_variable, an_arg)|
      end

      context 'an integer feature flag' do
        include_examples 'does not set any flags as used', %Q|#{feature_flag_method}(123)|
      end
    end
  end

  %w[
    use_rugged?
  ].each do |feature_flag_method|
    context "#{feature_flag_method} method" do
      context 'a string feature flag' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}(arg, "baz")|, 'baz'
      end

      context 'a symbol feature flag' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}(arg, :baz)|, 'baz'
      end

      context 'an interpolated string feature flag with a string prefix' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}(arg, "foo_\#{bar}")|, %w[foo_hello foo_world]
      end

      context 'an interpolated symbol feature flag with a string prefix' do
        include_examples 'sets flag as used', %Q|#{feature_flag_method}(arg, :"foo_\#{bar}")|, %w[foo_hello foo_world]
      end

      context 'an interpolated string feature flag with a string prefix and suffix' do
        include_examples 'does not set any flags as used', %Q|#{feature_flag_method}(arg, :"foo_\#{bar}_baz")|
      end

      context 'a dynamic string feature flag as a variable' do
        include_examples 'does not set any flags as used', %Q|#{feature_flag_method}(a_variable, an_arg)|
      end

      context 'an integer feature flag' do
        include_examples 'does not set any flags as used', %Q|#{feature_flag_method}(arg, 123)|
      end
    end
  end

  describe 'self.limit_feature_flag = :foo' do
    include_examples 'sets flag as used', 'self.limit_feature_flag = :foo', 'foo'
  end

  describe 'FEATURE_FLAG = :foo' do
    include_examples 'sets flag as used', 'FEATURE_FLAG = :foo', 'foo'
  end

  describe 'Worker `data_consistency` method' do
    include_examples 'sets flag as used', 'data_consistency :delayed, feature_flag: :foo', 'foo'
    include_examples 'does not set any flags as used', 'data_consistency :delayed'
  end

  describe 'Worker `deduplicate` method' do
    include_examples 'sets flag as used', 'deduplicate :delayed, feature_flag: :foo', 'foo'
    include_examples 'does not set any flags as used', 'deduplicate :delayed'
  end

  describe 'GraphQL `field` method' do
    before do
      allow(cop).to receive(:in_graphql_types?).and_return(true)
    end

    include_examples 'sets flag as used', 'field :runners, Types::Ci::RunnerType.connection_type, null: true, feature_flag: :foo', 'foo'
    include_examples 'sets flag as used', 'field :runners, null: true, feature_flag: :foo', 'foo'
    include_examples 'does not set any flags as used', 'field :solution'
    include_examples 'does not set any flags as used', 'field :runners, Types::Ci::RunnerType.connection_type'
    include_examples 'does not set any flags as used', 'field :runners, Types::Ci::RunnerType.connection_type, null: true, description: "hello world"'
    include_examples 'does not set any flags as used', 'field :solution, type: GraphQL::STRING_TYPE, null: true, description: "URL to the vulnerabilitys details page."'
  end

  describe "tracking of usage data metrics known events happens at the beginning of inspection" do
    let(:usage_data_counters_known_event_feature_flags) { ['an_event_feature_flag'] }

    before do
      allow(cop).to receive(:usage_data_counters_known_event_feature_flags).and_return(usage_data_counters_known_event_feature_flags)
    end

    include_examples 'sets flag as used', "FEATURE_FLAG = :foo", %w[foo an_event_feature_flag]
  end
end
