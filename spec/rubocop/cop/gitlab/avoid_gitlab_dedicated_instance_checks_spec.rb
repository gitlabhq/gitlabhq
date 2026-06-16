# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'
require_relative '../../../../rubocop/cop/gitlab/avoid_gitlab_dedicated_instance_checks'

RSpec.describe RuboCop::Cop::Gitlab::AvoidGitlabDedicatedInstanceChecks, feature_category: :tooling do
  describe 'bad examples' do
    where(:code) do
      [
        'Gitlab::CurrentSettings.gitlab_dedicated_instance?',
        '::Gitlab::CurrentSettings.gitlab_dedicated_instance?',
        'Gitlab::Dedicated.dedicated_instance?',
        '::Gitlab::Dedicated.dedicated_instance?'
      ]
    end

    with_them do
      it 'registers an offense' do
        expect_offense(<<~RUBY, node: code)
          return if %{node}
                    ^{node} Avoid the use of [...]
        RUBY
      end
    end
  end

  describe 'offense message' do
    it 'includes the full source for CurrentSettings calls' do
      expect_offense(<<~RUBY)
        return if Gitlab::CurrentSettings.gitlab_dedicated_instance?
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid the use of `Gitlab::CurrentSettings.gitlab_dedicated_instance?`. Use Gitlab::Dedicated.feature_available?. Instance checks create untested code paths since they are false by default in tests. See https://docs.gitlab.com/development/ee_features/#dedicated-instance-features
      RUBY
    end

    it 'includes the full source for Dedicated module calls' do
      expect_offense(<<~RUBY)
        return if Gitlab::Dedicated.dedicated_instance?
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid the use of `Gitlab::Dedicated.dedicated_instance?`. Use Gitlab::Dedicated.feature_available?. Instance checks create untested code paths since they are false by default in tests. See https://docs.gitlab.com/development/ee_features/#dedicated-instance-features
      RUBY
    end
  end

  describe 'good examples' do
    where(:code) do
      [
        'Gitlab::Dedicated.feature_available?(:foo)',
        'gitlab_dedicated_instance?',
        'dedicated_instance?',
        'Gitlab::CurrentSettings.gitlab_dedicated_setting?',
        'Gitlab::Dedicated.feature_available?'
      ]
    end

    with_them do
      it 'does not register an offense' do
        expect_no_offenses(code)
      end
    end
  end
end
