# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/same_as_description'

RSpec.describe RuboCop::Cop::API::SameAsDescription, feature_category: :api do
  let(:msg) do
    'Parameter uses `same_as:` validation but `desc:` is missing the required phrase. ' \
      "Add \"Must match the '<param-name>' parameter\" to the desc."
  end

  # === Offense Test ===

  it 'flags a same_as parameter with no desc' do
    expect_offense(<<~RUBY)
      class MyApi < Grape::API::Instance
        params do
          requires :password_confirmation, same_as: :password
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      end
    RUBY
  end

  it 'flags a same_as parameter whose desc references the wrong parameter name' do
    expect_offense(<<~RUBY)
      class MyApi < Grape::API::Instance
        params do
          requires :password_confirmation, same_as: :password, desc: "Must match the 'email' parameter"
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      end
    RUBY
  end

  it 'flags an optional parameter whose desc references the wrong parameter name' do
    expect_offense(<<~RUBY)
      class MyApi < Grape::API::Instance
        params do
          optional :password_confirmation, same_as: :password, desc: "Must match the 'email' parameter"
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      end
    RUBY
  end

  it 'flags a same_as parameter whose non-literal desc is missing the required phrase' do
    expect_offense(<<~RUBY)
      class MyApi < Grape::API::Instance
        params do
          requires :password_confirmation, desc: _("some text"), same_as: :password
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      end
    RUBY

    expect_no_corrections
  end

  # === No-Offense Test ===

  it 'does not flag a same_as parameter whose non-literal desc includes the required phrase' do
    expect_no_offenses(<<~RUBY)
      class MyApi < Grape::API::Instance
        params do
          requires :password_confirmation, desc: _("Must match the 'password' parameter"), same_as: :password
        end
      end
    RUBY
  end

  it 'does not flag an optional parameter whose desc includes the required phrase' do
    expect_no_offenses(<<~RUBY)
      class MyApi < Grape::API::Instance
        params do
          optional :password_confirmation, same_as: :password, desc: "Must match the 'password' parameter"
        end
      end
    RUBY
  end

  it 'does not flag a same_as parameter whose desc consists of the required phrase' do
    expect_no_offenses(<<~RUBY)
      class MyApi < Grape::API::Instance
        params do
          requires :password_confirmation, same_as: :password, desc: "Must match the 'password' parameter. Password confirmation."
        end
      end
    RUBY
  end

  it 'does not flag parameters that do not use same_as' do
    expect_no_offenses(<<~RUBY)
      class MyApi < Grape::API::Instance
        params do
          requires :password, type: String, desc: 'The password'
        end
      end
    RUBY
  end

  it 'does not flag a requires call with a non-hash second argument' do
    expect_no_offenses(<<~RUBY)
      class MyApi < Grape::API::Instance
        params do
          requires :password, Integer
        end
      end
    RUBY
  end

  it 'does not flag a same_as parameter whose desc appears before same_as in the hash' do
    expect_no_offenses(<<~RUBY)
      class MyApi < Grape::API::Instance
        params do
          requires :password_confirmation, desc: "Must match the 'password' parameter. Password confirmation.", same_as: :password
        end
      end
    RUBY
  end

  # === AutoCorrector Test ===

  it 'autocorrects by inserting a desc when it is absent' do
    expect_offense(<<~RUBY)
      class MyApi < Grape::API::Instance
        params do
          requires :password_confirmation, same_as: :password
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class MyApi < Grape::API::Instance
        params do
          requires :password_confirmation, same_as: :password, desc: "Must match the 'password' parameter"
        end
      end
    RUBY
  end

  it 'autocorrects by appending the required phrase to an existing non-compliant desc' do
    expect_offense(<<~RUBY)
      class MyApi < Grape::API::Instance
        params do
          requires :password_confirmation, same_as: :password, desc: 'Password confirmation'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class MyApi < Grape::API::Instance
        params do
          requires :password_confirmation, same_as: :password, desc: "Password confirmation. Must match the 'password' parameter"
        end
      end
    RUBY
  end
end
