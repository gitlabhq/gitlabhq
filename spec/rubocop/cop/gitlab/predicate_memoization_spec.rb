require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/gitlab/predicate_memoization'

describe RuboCop::Cop::Gitlab::PredicateMemoization do
  include CopHelper

  subject(:cop) { described_class.new }

  shared_examples('registering offense') do |options|
    let(:offending_lines) { options[:offending_lines] }

    it 'registers an offense when a predicate method is memoizing via ivar' do
      inspect_source(source)

      aggregate_failures do
        expect(cop.offenses.size).to eq(offending_lines.size)
        expect(cop.offenses.map(&:line)).to eq(offending_lines)
      end
    end
  end

  shared_examples('not registering offense') do
    it 'does not register offenses' do
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end
  end

  context 'when source is a predicate method memoizing via ivar' do
    it_behaves_like 'registering offense', offending_lines: [3] do
      let(:source) do
        <<~RUBY
          class C
            def really?
              @really ||= true
            end
          end
        RUBY
      end
    end

    it_behaves_like 'registering offense', offending_lines: [4] do
      let(:source) do
        <<~RUBY
          class C
            def really?
              value = true
              @really ||= value
            end
          end
        RUBY
      end
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
end
