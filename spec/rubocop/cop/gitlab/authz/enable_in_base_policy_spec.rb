# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../../rubocop/cop/gitlab/authz/enable_in_base_policy'

RSpec.describe RuboCop::Cop::Gitlab::Authz::EnableInBasePolicy, feature_category: :permissions do
  include RuboCop::RSpec::ExpectOffense

  let(:cop) { described_class.new }

  let(:base_policy_filename) { 'app/policies/base_policy.rb' }
  let(:ee_base_policy_filename) { 'ee/app/policies/ee/base_policy.rb' }
  let(:regular_policy_filename) { 'app/policies/project_policy.rb' }

  let(:message) do
    'Gitlab/Authz/EnableInBasePolicy: Do not call `enable` in BasePolicy. ' \
      'Move these into the concrete policy where the resource context is explicit.'
  end

  it 'registers an offense for chained `.enable` (rule { ... }.enable ...)' do
    expect_offense(<<~RUBY, base_policy_filename)
        class BasePolicy < DeclarativePolicy::Base
          rule { auditor }.enable :read_all_resources
                           ^^^^^^ #{message}
        end
    RUBY
  end

  it 'registers an offense for `enable` inside a `.policy do ... end` block' do
    expect_offense(<<~RUBY, base_policy_filename)
        class BasePolicy < DeclarativePolicy::Base
          rule { admin }.policy do
            enable :read_all_resources
            ^^^^^^ #{message}
          end
        end
    RUBY
  end
end
