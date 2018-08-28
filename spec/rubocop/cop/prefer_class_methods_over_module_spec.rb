# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/prefer_class_methods_over_module'

describe RuboCop::Cop::PreferClassMethodsOverModule do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags violation when using module ClassMethods' do
    expect_offense(<<~RUBY)
      module Foo
        extend ActiveSupport::Concern

        module ClassMethods
        ^^^^^^^^^^^^^^^^^^^ Do not use module ClassMethods, use class_methods block instead.
          def a_class_method
          end
        end
      end
    RUBY
  end

  it "doesn't flag violation when using class_methods" do
    expect_no_offenses(<<~RUBY)
      module Foo
        extend ActiveSupport::Concern

        class_methods do
          def a_class_method
          end
        end
      end
    RUBY
  end

  it "doesn't flag violation when module is not extending ActiveSupport::Concern" do
    expect_no_offenses(<<~RUBY)
      module Foo
        module ClassMethods
          def a_class_method
          end
        end
      end
    RUBY
  end

  it "doesn't flag violation when ClassMethods is used inside a class" do
    expect_no_offenses(<<~RUBY)
      class Foo
        module ClassMethods
          def a_class_method
          end
        end
      end
    RUBY
  end

  it "doesn't flag violation when not using either class_methods or ClassMethods" do
    expect_no_offenses(<<~RUBY)
      module Foo
        extend ActiveSupport::Concern

        def a_method
        end
      end
    RUBY
  end

  it 'autocorrects ClassMethods into class_methods' do
    source = <<~RUBY
      module Foo
        extend ActiveSupport::Concern

        module ClassMethods
          def a_class_method
          end
        end
      end
    RUBY
    autocorrected = autocorrect_source(source)

    expected_source = <<~RUBY
      module Foo
        extend ActiveSupport::Concern

        class_methods do
          def a_class_method
          end
        end
      end
    RUBY
    expect(autocorrected).to eq(expected_source)
  end
end
