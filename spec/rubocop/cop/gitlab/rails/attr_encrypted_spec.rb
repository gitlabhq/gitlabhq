# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../../rubocop/cop/gitlab/rails/attr_encrypted'

RSpec.describe RuboCop::Cop::Gitlab::Rails::AttrEncrypted, feature_category: :shared do
  it 'does not raise an offense if not using attr_encrypted' do
    expect_no_offenses('encrypts :secret')
  end

  it 'raises an offense when using attr_encrypted' do
    expect_offense(<<~RUBY)
      class Dummy < ApplicationRecord
        attr_encrypted :secret,
        ^^^^^^^^^^^^^^^^^^^^^^^ Use `encrypts` over deprecated `attr_encrypted` to encrypt a column. See https://docs.gitlab.com/development/migration_style_guide/#encrypted-attributes
          mode: :per_attribute_iv_and_salt,
          insecure_mode: true,
          key: :db_key_base,
          algorithm: 'aes-256-cbc'
      end
    RUBY

    expect_correction(<<~RUBY)
      class Dummy < ApplicationRecord
        encrypts :secret
      end
    RUBY
  end
end
