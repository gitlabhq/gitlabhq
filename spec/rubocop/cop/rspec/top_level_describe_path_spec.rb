# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/rspec/top_level_describe_path'

RSpec.describe RuboCop::Cop::RSpec::TopLevelDescribePath do
  subject(:cop) { described_class.new }

  context 'when the file ends in _spec.rb' do
    it 'registers no offenses' do
      expect_no_offenses(<<~SOURCE, 'spec/foo_spec.rb')
        describe 'Foo' do
        end
      SOURCE
    end
  end

  context 'when the file is a frontend fixture' do
    it 'registers no offenses' do
      expect_no_offenses(<<~SOURCE, 'spec/frontend/fixtures/foo.rb')
        describe 'Foo' do
        end
      SOURCE
    end
  end

  context 'when the describe is in a shared example' do
    context 'with shared_examples' do
      it 'registers no offenses' do
        expect_no_offenses(<<~SOURCE, 'spec/foo.rb')
          shared_examples 'Foo' do
            describe '#bar' do
            end
          end
        SOURCE
      end
    end

    context 'with shared_examples_for' do
      it 'registers no offenses' do
        expect_no_offenses(<<~SOURCE, 'spec/foo.rb')
          shared_examples_for 'Foo' do
            describe '#bar' do
            end
          end
        SOURCE
      end
    end
  end

  context 'when the describe is at the top level' do
    it 'marks the describe as offending' do
      expect_offense(<<~SOURCE, 'spec/foo.rb')
        describe 'Foo' do
        ^^^^^^^^^^^^^^ #{described_class::MESSAGE}
        end
      SOURCE
    end
  end
end
