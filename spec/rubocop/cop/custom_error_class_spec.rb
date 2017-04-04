require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../rubocop/cop/custom_error_class'

describe RuboCop::Cop::CustomErrorClass do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'when a class has a body' do
    it 'does nothing' do
      inspect_source(cop, 'class CustomError < StandardError; def foo; end; end')

      expect(cop.offenses).to be_empty
    end
  end

  context 'when a class has no explicit superclass' do
    it 'does nothing' do
      inspect_source(cop, 'class CustomError; end')

      expect(cop.offenses).to be_empty
    end
  end

  context 'when a class has a superclass that does not end in Error' do
    it 'does nothing' do
      inspect_source(cop, 'class CustomError < BasicObject; end')

      expect(cop.offenses).to be_empty
    end
  end

  context 'when a class is empty and inherits from a class ending in Error' do
    context 'when the class is on a single line' do
      let(:source) do
        <<-SOURCE
          module Foo
            class CustomError < Bar::Baz::BaseError; end
          end
        SOURCE
      end

      let(:expected) do
        <<-EXPECTED
          module Foo
            CustomError = Class.new(Bar::Baz::BaseError)
          end
        EXPECTED
      end

      it 'registers an offense' do
        expected_highlights = source.split("\n")[1].strip

        inspect_source(cop, source)

        aggregate_failures do
          expect(cop.offenses.size).to eq(1)
          expect(cop.offenses.map(&:line)).to eq([2])
          expect(cop.highlights).to contain_exactly(expected_highlights)
        end
      end

      it 'autocorrects to the right version' do
        autocorrected = autocorrect_source(cop, source, 'foo/custom_error.rb')

        expect(autocorrected).to eq(expected)
      end
    end

    context 'when the class is on multiple lines' do
      let(:source) do
        <<-SOURCE
          module Foo
            class CustomError < Bar::Baz::BaseError
            end
          end
        SOURCE
      end

      let(:expected) do
        <<-EXPECTED
          module Foo
            CustomError = Class.new(Bar::Baz::BaseError)
          end
        EXPECTED
      end

      it 'registers an offense' do
        expected_highlights = source.split("\n")[1..2].join("\n").strip

        inspect_source(cop, source)

        aggregate_failures do
          expect(cop.offenses.size).to eq(1)
          expect(cop.offenses.map(&:line)).to eq([2])
          expect(cop.highlights).to contain_exactly(expected_highlights)
        end
      end

      it 'autocorrects to the right version' do
        autocorrected = autocorrect_source(cop, source, 'foo/custom_error.rb')

        expect(autocorrected).to eq(expected)
      end
    end
  end
end
