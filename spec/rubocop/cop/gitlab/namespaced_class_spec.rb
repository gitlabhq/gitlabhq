# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/namespaced_class'

RSpec.describe RuboCop::Cop::Gitlab::NamespacedClass, feature_category: :shared do
  shared_examples 'enforces namespaced classes' do
    def namespaced(code)
      return code unless namespace

      <<~SOURCE
        module #{namespace}
        #{code}
        end
      SOURCE
    end

    it 'flags a class definition without additional namespace' do
      expect_offense(namespaced(<<~SOURCE))
        class MyClass
              ^^^^^^^ #{described_class::MSG}
        end
      SOURCE
    end

    it 'flags a compact class definition without additional namespace' do
      expect_offense(<<~SOURCE, namespace: namespace)
        class %{namespace}::MyClass
              ^{namespace}^^^^^^^^^ #{described_class::MSG}
        end
      SOURCE
    end

    it 'flags a class definition with inheritance without additional namespace' do
      expect_offense(namespaced(<<~SOURCE))
        class MyClass < ApplicationRecord
              ^^^^^^^ #{described_class::MSG}
          def some_method
            true
          end
        end
      SOURCE
    end

    it 'does not flag the class definition with namespace in separate lines' do
      expect_no_offenses(namespaced(<<~SOURCE))
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
      expect_no_offenses(namespaced(<<~SOURCE))
        module TopLevelModule
          module NestedModule
            class MyClass
            end
          end
        end
      SOURCE
    end

    it 'does not flag the class definition nested inside namespaced class' do
      expect_no_offenses(namespaced(<<~SOURCE))
        module TopLevelModule
          class TopLevelClass
            class MyClass
            end
          end
        end
      SOURCE
    end

    it 'does not flag the class definition nested inside compact namespace' do
      expect_no_offenses(<<~SOURCE)
        module #{namespace}::TopLevelModule
          class MyClass
          end
        end
      SOURCE
    end

    it 'does not flag a compact namespaced class definition' do
      expect_no_offenses(namespaced(<<~SOURCE))
        class MyModule::MyClass < ApplicationRecord
        end
      SOURCE
    end

    it 'does not flag a truly compact namespaced class definition' do
      expect_no_offenses(<<~SOURCE, namespace: namespace)
        class %{namespace}::MyModule::MyClass < ApplicationRecord
        end
      SOURCE
    end
  end

  context 'without top-level namespace' do
    let(:namespace) { nil }

    it_behaves_like 'enforces namespaced classes'
  end

  context 'with Gitlab namespace' do
    let(:namespace) { 'Gitlab' }

    it_behaves_like 'enforces namespaced classes'
  end

  context 'with ::Gitlab namespace' do
    let(:namespace) { '::Gitlab' }

    it_behaves_like 'enforces namespaced classes'
  end
end
