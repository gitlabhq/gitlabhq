# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/search/namespaced_class'

RSpec.describe RuboCop::Cop::Search::NamespacedClass, feature_category: :global_search do
  %w[Search Zoekt Elastic].each do |keyword|
    context 'when Search root namespace is not used' do
      it 'flags a class definition without Search namespace' do
        expect_offense(<<~'SOURCE', keyword: keyword, msg: described_class::MSG)
          class My%{keyword}Class
                ^^^{keyword}^^^^^ %{msg}
          end
        SOURCE

        expect_offense(<<~'SOURCE', keyword: keyword, msg: described_class::MSG)
        class %{keyword}::MyClass < ApplicationRecord
              ^{keyword}^^^^^^^^^ %{msg}
          def some_method
            true
          end
        end
        SOURCE

        expect_offense(<<~'SOURCE', keyword: keyword, msg: described_class::MSG)
        class MyClass < %{keyword}::Class
              ^^^^^^^ %{msg}
          def some_method
            true
          end
        end
        SOURCE
      end

      it "flags a class definition with #{keyword} in root namespace module" do
        expect_offense(<<~'SOURCE', keyword: keyword, msg: described_class::MSG)
          module %{keyword}Module
            class MyClass < ApplicationRecord
                  ^^^^^^^ %{msg}
              def some_method
                true
              end
            end
          end
        SOURCE
      end

      it 'flags a module in EE module' do
        expect_offense(<<~'SOURCE', keyword: keyword, msg: described_class::MSG)
          module EE
            module %{keyword}Controller
                   ^{keyword}^^^^^^^^^^ %{msg}
              def some_method
                true
              end
            end
          end
        SOURCE
      end
    end

    context 'when Search root namespace is used' do
      it 'does not flag a class definition with Search as root namespace module' do
        expect_no_offenses(<<~SOURCE, keyword: keyword)
          module Search
            class %{keyword}::MyClass < ApplicationRecord
              def some_method
                true
              end
            end
          end
        SOURCE
      end

      it 'does not a flag a class definition with Search as root namespace inline' do
        expect_no_offenses(<<~SOURCE, keyword: keyword)
          class Search::%{keyword}::MyClass < ApplicationRecord
            def some_method
              true
            end
          end
        SOURCE
      end

      it 'does not a flag a class definition with Search as root namespace in EE' do
        expect_no_offenses(<<~SOURCE, keyword: keyword)
          module EE
            module Search
              class %{keyword}::MyClass < ApplicationRecord
                def some_method
                  true
                end
              end
            end
          end
        SOURCE
      end
    end
  end
end
