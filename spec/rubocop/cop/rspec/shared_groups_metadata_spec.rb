# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'

require_relative '../../../../rubocop/cop/rspec/shared_groups_metadata'

RSpec.describe RuboCop::Cop::RSpec::SharedGroupsMetadata, feature_category: :tooling do
  context 'with hash metadata' do
    it 'flags metadata in shared example' do
      expect_offense(<<~RUBY)
          RSpec.shared_examples 'foo', feature_category: :shared do
                                       ^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid using metadata on shared examples and shared context. They might cause flaky tests. See https://gitlab.com/gitlab-org/gitlab/-/issues/404388
          end

          shared_examples 'foo', feature_category: :shared do
                                 ^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid using metadata on shared examples and shared context. They might cause flaky tests. See https://gitlab.com/gitlab-org/gitlab/-/issues/404388
          end
      RUBY
    end

    it 'flags metadata in shared context' do
      expect_offense(<<~RUBY)
          RSpec.shared_context 'foo', feature_category: :shared do
                                      ^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid using metadata on shared examples and shared context. They might cause flaky tests. See https://gitlab.com/gitlab-org/gitlab/-/issues/404388
          end

          shared_context 'foo', feature_category: :shared do
                                ^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid using metadata on shared examples and shared context. They might cause flaky tests. See https://gitlab.com/gitlab-org/gitlab/-/issues/404388
          end
      RUBY
    end
  end

  context 'with symbol metadata' do
    it 'flags metadata in shared example' do
      expect_offense(<<~RUBY)
          RSpec.shared_examples 'foo', :aggregate_failures do
                                       ^^^^^^^^^^^^^^^^^^^ Avoid using metadata on shared examples and shared context. They might cause flaky tests. See https://gitlab.com/gitlab-org/gitlab/-/issues/404388
          end

          shared_examples 'foo', :aggregate_failures do
                                 ^^^^^^^^^^^^^^^^^^^ Avoid using metadata on shared examples and shared context. They might cause flaky tests. See https://gitlab.com/gitlab-org/gitlab/-/issues/404388
          end
      RUBY
    end

    it 'flags metadata in shared context' do
      expect_offense(<<~RUBY)
          RSpec.shared_context 'foo', :aggregate_failures do
                                      ^^^^^^^^^^^^^^^^^^^ Avoid using metadata on shared examples and shared context. They might cause flaky tests. See https://gitlab.com/gitlab-org/gitlab/-/issues/404388
          end

          shared_context 'foo', :aggregate_failures do
                                ^^^^^^^^^^^^^^^^^^^ Avoid using metadata on shared examples and shared context. They might cause flaky tests. See https://gitlab.com/gitlab-org/gitlab/-/issues/404388
          end
      RUBY
    end
  end

  it 'does not flag if feature category is missing' do
    expect_no_offenses(<<~RUBY)
        RSpec.shared_examples 'foo' do
        end

        shared_examples 'foo' do
        end
    RUBY
  end
end
