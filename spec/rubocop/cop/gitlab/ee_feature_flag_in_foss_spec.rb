# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/ee_feature_flag_in_foss'

RSpec.describe RuboCop::Cop::Gitlab::EeFeatureFlagInFoss, feature_category: :scalability do
  let(:msg) do
    'Feature flag `%{flag}` is defined in `ee/config/feature_flags/` but used in FOSS code. ' \
      'Move this code to the `ee/` directory or move the feature flag definition to `config/feature_flags/`.'
  end

  let(:ee_feature_flags) { %w[ee_only_flag] }

  before do
    allow(RuboCop::FeatureFlags).to receive(:ee_feature_flag_names).and_return(ee_feature_flags)
  end

  shared_examples 'offense for EE-only flag in FOSS' do |code, flag_name|
    context 'in FOSS code' do
      it 'registers an offense' do
        expect_offense(<<~RUBY, rails_root_join('lib/gitlab/gon_helper.rb'))
          class Foo
            #{code}
            #{'^' * code.length} #{format(msg, flag: flag_name)}
          end
        RUBY
      end
    end

    context 'in EE code' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY, rails_root_join('ee/lib/ee/gitlab/gon_helper.rb'))
          class Foo
            #{code}
          end
        RUBY
      end
    end
  end

  shared_examples 'no offense for FOSS flag' do |code|
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY, rails_root_join('lib/gitlab/gon_helper.rb'))
        class Foo
          #{code}
        end
      RUBY
    end
  end

  describe 'Feature.enabled?' do
    include_examples 'offense for EE-only flag in FOSS',
      'Feature.enabled?(:ee_only_flag)', 'ee_only_flag'

    include_examples 'no offense for FOSS flag',
      'Feature.enabled?(:foss_flag)'
  end

  describe 'Feature.disabled?' do
    include_examples 'offense for EE-only flag in FOSS',
      'Feature.disabled?(:ee_only_flag)', 'ee_only_flag'

    include_examples 'no offense for FOSS flag',
      'Feature.disabled?(:foss_flag)'
  end

  describe 'push_frontend_feature_flag' do
    include_examples 'offense for EE-only flag in FOSS',
      'push_frontend_feature_flag(:ee_only_flag, current_user)', 'ee_only_flag'

    include_examples 'no offense for FOSS flag',
      'push_frontend_feature_flag(:foss_flag, current_user)'
  end

  describe 'push_force_frontend_feature_flag' do
    include_examples 'offense for EE-only flag in FOSS',
      'push_force_frontend_feature_flag(:ee_only_flag, current_user)', 'ee_only_flag'

    include_examples 'no offense for FOSS flag',
      'push_force_frontend_feature_flag(:foss_flag, current_user)'
  end

  describe 'FEATURE_FLAG constant' do
    include_examples 'offense for EE-only flag in FOSS',
      'FEATURE_FLAG = :ee_only_flag', 'ee_only_flag'

    include_examples 'no offense for FOSS flag',
      'FEATURE_FLAG = :foss_flag'
  end

  describe 'ROUTING_FEATURE_FLAG constant' do
    include_examples 'offense for EE-only flag in FOSS',
      'ROUTING_FEATURE_FLAG = :ee_only_flag', 'ee_only_flag'

    include_examples 'no offense for FOSS flag',
      'ROUTING_FEATURE_FLAG = :foss_flag'
  end

  describe 'limit_feature_flag=' do
    include_examples 'offense for EE-only flag in FOSS',
      'self.limit_feature_flag = :ee_only_flag', 'ee_only_flag'

    include_examples 'no offense for FOSS flag',
      'self.limit_feature_flag = :foss_flag'
  end

  describe 'limit_feature_flag_for_override=' do
    include_examples 'offense for EE-only flag in FOSS',
      'self.limit_feature_flag_for_override = :ee_only_flag', 'ee_only_flag'

    include_examples 'no offense for FOSS flag',
      'self.limit_feature_flag_for_override = :foss_flag'
  end

  describe 'string feature flags' do
    include_examples 'offense for EE-only flag in FOSS',
      'Feature.enabled?("ee_only_flag")', 'ee_only_flag'

    include_examples 'no offense for FOSS flag',
      'Feature.enabled?("foss_flag")'
  end

  describe 'Feature::Gitaly' do
    let(:ee_feature_flags) { %w[gitaly_ee_only_flag] }

    include_examples 'offense for EE-only flag in FOSS',
      'Feature::Gitaly.enabled?(:ee_only_flag)', 'gitaly_ee_only_flag'
  end

  describe 'Feature::Kas' do
    let(:ee_feature_flags) { %w[kas_ee_only_flag] }

    include_examples 'offense for EE-only flag in FOSS',
      'Feature::Kas.enabled?(:ee_only_flag)', 'kas_ee_only_flag'
  end

  describe 'dynamic feature flags' do
    it 'does not register an offense for variables' do
      expect_no_offenses(<<~RUBY, 'lib/gitlab/gon_helper.rb')
        class Foo
          Feature.enabled?(flag_variable)
        end
      RUBY
    end

    it 'does not register an offense for interpolated strings' do
      expect_no_offenses(<<~RUBY, 'lib/gitlab/gon_helper.rb')
        class Foo
          Feature.enabled?("prefix_\#{suffix}")
        end
      RUBY
    end
  end
end
