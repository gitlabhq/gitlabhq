# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/gitlab/namespaced_class'

RSpec.describe RuboCop::Cop::Gitlab::NamespacedClass do
  subject(:cop) { described_class.new }

  it 'flags a class definition without namespace' do
    expect_offense(<<~SOURCE)
      class MyClass
      ^^^^^^^^^^^^^ #{described_class::MSG}
      end
    SOURCE
  end

  it 'flags a class definition with inheritance without namespace' do
    expect_offense(<<~SOURCE)
      class MyClass < ApplicationRecord
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
        def some_method
          true
        end
      end
    SOURCE
  end

  it 'does not flag the class definition with namespace in separate lines' do
    expect_no_offenses(<<~SOURCE)
      module MyModule
        class MyClass < ApplicationRecord
        end

        class MyOtherClass
          def other_method
            1 + 1
          end
        end
      end
    SOURCE
  end

  it 'does not flag the class definition with nested namespace in separate lines' do
    expect_no_offenses(<<~SOURCE)
      module TopLevelModule
        module NestedModule
          class MyClass
          end
        end
      end
    SOURCE
  end

  it 'does not flag the class definition nested inside namespaced class' do
    expect_no_offenses(<<~SOURCE)
      module TopLevelModule
        class TopLevelClass
          class MyClass
          end
        end
      end
    SOURCE
  end

  it 'does not flag a compact namespaced class definition' do
    expect_no_offenses(<<~SOURCE)
      class MyModule::MyClass < ApplicationRecord
      end
    SOURCE
  end
end
