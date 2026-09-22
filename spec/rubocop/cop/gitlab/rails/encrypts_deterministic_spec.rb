# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../../rubocop/cop/gitlab/rails/encrypts_deterministic'

RSpec.describe RuboCop::Cop::Gitlab::Rails::EncryptsDeterministic, feature_category: :rails_platform do
  it 'does not raise an offense for encrypts without deterministic' do
    expect_no_offenses('encrypts :secret')
  end

  it 'does not raise an offense for encrypts with deterministic: false' do
    expect_no_offenses('encrypts :secret, deterministic: false')
  end

  it 'does not raise an offense for encrypts with an unrelated keyword argument' do
    expect_no_offenses('encrypts :secret, ignore_case: true')
  end

  it 'raises an offense for encrypts with deterministic: true' do
    expect_offense(<<~RUBY)
      encrypts :secret, deterministic: true
                        ^^^^^^^^^^^^^^^^^^^ [...]
    RUBY
  end

  it 'raises an offense for encrypts with a non-false deterministic value' do
    expect_offense(<<~RUBY)
      encrypts :secret, deterministic: { fixed: false }
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ [...]
    RUBY
  end
end
