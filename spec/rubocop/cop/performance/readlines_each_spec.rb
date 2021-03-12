# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/performance/readlines_each'

RSpec.describe RuboCop::Cop::Performance::ReadlinesEach do
  subject(:cop) { described_class.new }

  let(:message) { 'Avoid `IO.readlines.each`, since it reads contents into memory in full. Use `IO.each_line` or `IO.each` instead.' }

  shared_examples_for(:class_read) do |klass|
    context "and it is called as a class method on #{klass}" do
      it 'flags it as an offense' do
        leading_readline = "#{klass}.readlines(file_path)."
        padding = " " * leading_readline.length
        node = "#{leading_readline}each { |line| puts line }"

        expect_offense(<<~CODE, node: node)
          %{node}
          #{padding}^^^^ Avoid `IO.readlines.each`, since it reads contents into memory in full. [...]
        CODE
      end
    end

    context 'when just using readlines without each' do
      it 'does not flag it as an offense' do
        expect_no_offenses "contents = #{klass}.readlines(file_path)"
      end
    end
  end

  context 'when reading all lines using IO.readlines.each' do
    %w(IO File).each do |klass|
      it_behaves_like(:class_read, klass)
    end

    context 'and it is called as an instance method on a return value' do
      it 'flags it as an offense' do
        expect_offense <<~SOURCE
          get_file.readlines.each { |line| puts line }
                             ^^^^ #{message}
        SOURCE
      end
    end

    context 'and it is called as an instance method on an assigned variable' do
      it 'flags it as an offense' do
        expect_offense <<~SOURCE
          file = File.new(path)
          file.readlines.each { |line| puts line }
                         ^^^^ #{message}
        SOURCE
      end
    end

    context 'and it is called as an instance method on a new object' do
      it 'flags it as an offense' do
        expect_offense <<~SOURCE
          File.new(path).readlines.each { |line| puts line }
                                   ^^^^ #{message}
        SOURCE
      end
    end

    it 'autocorrects `readlines.each` to `each_line`' do
      expect_offense(<<~CODE)
        obj.readlines.each { |line| line }
                      ^^^^ Avoid `IO.readlines.each`, since it reads contents into memory in full. [...]
      CODE

      expect_correction(<<~CODE)
        obj.each_line { |line| line }
      CODE
    end
  end

  context 'when just using readlines without each' do
    it 'does not flag it as an offense' do
      expect_no_offenses 'contents = my_file.readlines'
    end
  end
end
