# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/predicate_memoization'

RSpec.describe RuboCop::Cop::Gitlab::PredicateMemoization do
  shared_examples('not registering offense') do
    it 'does not register offenses' do
      expect_no_offenses(source)
    end
  end

  context 'when source is a predicate method using ivar with assignment' do
    it_behaves_like 'not registering offense' do
      let(:source) do
        <<~RUBY
          class C
            def really?
              @really = true
            end
          end
        RUBY
      end
    end
  end

  context 'when source is a predicate method using local with ||=' do
    it_behaves_like 'not registering offense' do
      let(:source) do
        <<~RUBY
          class C
            def really?
              really ||= true
            end
          end
        RUBY
      end
    end
  end

  context 'when source is a regular method memoizing via ivar' do
    it_behaves_like 'not registering offense' do
      let(:source) do
        <<~RUBY
          class C
            def really
              @really ||= true
            end
          end
        RUBY
      end
    end
  end

  context 'when source is a predicate method memoizing via ivar' do
    let(:msg) { "Avoid using `@value ||= query` [...]" }

    context 'when assigning to boolean' do
      it 'registers an offense' do
        node = "@really ||= true"

        expect_offense(<<~CODE, node: node, msg: msg)
          class C
            def really?
              %{node}
              ^{node} %{msg}
            end
          end
        CODE
      end
    end

    context 'when assigning to another variable that is a boolean' do
      it 'registers an offense' do
        node = "@really ||= value"

        expect_offense(<<~CODE, node: node, msg: msg)
          class C
            def really?
              value = true
              %{node}
              ^{node} %{msg}
            end
          end
        CODE
      end
    end
  end
end
