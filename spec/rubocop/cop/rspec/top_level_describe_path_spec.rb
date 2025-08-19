# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/rspec/top_level_describe_path'

RSpec.describe RuboCop::Cop::RSpec::TopLevelDescribePath do
  context 'when the file ends in _spec.rb' do
    it 'registers no offenses' do
      expect_no_offenses(<<~RUBY, 'spec/foo_spec.rb')
        describe 'Foo' do
        end
      RUBY
    end
  end

  context 'when the file is a frontend fixture' do
    it 'registers no offenses' do
      expect_no_offenses(<<~RUBY, 'spec/frontend/fixtures/foo.rb')
        describe 'Foo' do
        end
      RUBY
    end
  end

  context 'when the describe is in a shared context' do
    context 'with shared_context' do
      it 'registers no offenses' do
        expect_no_offenses(<<~RUBY, 'spec/foo.rb')
          shared_context 'Foo' do
            describe '#bar' do
            end
          end
        RUBY
      end
    end
  end

  context 'when the describe is in a shared example' do
    context 'with shared_examples' do
      it 'registers no offenses' do
        expect_no_offenses(<<~RUBY, 'spec/foo.rb')
          shared_examples 'Foo' do
            describe '#bar' do
            end
          end
        RUBY
      end
    end

    context 'with shared_examples_for' do
      it 'registers no offenses' do
        expect_no_offenses(<<~RUBY, 'spec/foo.rb')
          shared_examples_for 'Foo' do
            describe '#bar' do
            end
          end
        RUBY
      end
    end
  end

  context 'when the describe is at the top level' do
    it 'marks the describe as offending' do
      expect_offense(<<~RUBY, 'spec/foo.rb')
        describe 'Foo' do
        ^^^^^^^^^^^^^^ #{described_class::MESSAGE}
        end
      RUBY
    end
  end
end
