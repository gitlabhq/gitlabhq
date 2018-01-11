require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/line_break_around_conditional_block'

describe RuboCop::Cop::LineBreakAroundConditionalBlock do
  include CopHelper

  subject(:cop) { described_class.new }

  shared_examples 'examples with conditional' do |conditional|
    it "flags violation for #{conditional} without line break before" do
      source = <<~RUBY
          do_something
          #{conditional} condition
            do_something_more
          end
      RUBY
      inspect_source(source)

      expect(cop.offenses.size).to eq(1)
      offense = cop.offenses.first

      expect(offense.line).to eq(2)
      expect(cop.highlights).to eq(["#{conditional} condition\n  do_something_more\nend"])
      expect(offense.message).to eq('Add a line break around conditional blocks')
    end

    it "flags violation for #{conditional} without line break after" do
      source = <<~RUBY
          #{conditional} condition
            do_something
          end
          do_something_more
      RUBY
      inspect_source(source)

      expect(cop.offenses.size).to eq(1)
      offense = cop.offenses.first

      expect(offense.line).to eq(1)
      expect(cop.highlights).to eq(["#{conditional} condition\n  do_something\nend"])
      expect(offense.message).to eq('Add a line break around conditional blocks')
    end

    it "doesn't flag violation for #{conditional} with line break before and after" do
      source = <<~RUBY
          #{conditional} condition
            do_something
          end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} preceded by a method definition" do
      source = <<~RUBY
          def a_method
            #{conditional} condition
              do_something
            end
          end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} preceded by a class definition" do
      source = <<~RUBY
          class Foo
            #{conditional} condition
              do_something
            end
          end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} preceded by a module definition" do
      source = <<~RUBY
          module Foo
            #{conditional} condition
              do_something
            end
          end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} preceded by a begin definition" do
      source = <<~RUBY
          begin
            #{conditional} condition
              do_something
            end
          end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} preceded by an assign/begin definition" do
      source = <<~RUBY
          @project ||= begin
            #{conditional} condition
              do_something
            end
          end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} preceded by a block definition" do
      source = <<~RUBY
          on_block(param_a) do |item|
            #{conditional} condition
              do_something
            end
          end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} preceded by a block definition using brackets" do
      source = <<~RUBY
          on_block(param_a) { |item|
            #{conditional} condition
              do_something
            end
          }
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} preceded by a comment" do
      source = <<~RUBY
          # a short comment
          #{conditional} condition
            do_something
          end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} preceded by an assignment" do
      source = <<~RUBY
          foo =
            #{conditional} condition
              do_something
            else
              do_something_more
            end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} preceded by a multiline comment" do
      source = <<~RUBY
          =begin
          a multiline comment
          =end
          #{conditional} condition
            do_something
          end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} preceded by another conditional" do
      source = <<~RUBY
          #{conditional} condition_a
            #{conditional} condition_b
              do_something
            end
          end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} preceded by an else" do
      source = <<~RUBY
           if condition_a
             do_something
           else
             #{conditional} condition_b
               do_something_extra
             end
           end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} preceded by an elsif" do
      source = <<~RUBY
           if condition_a
             do_something
           elsif condition_b
             #{conditional} condition_c
               do_something_extra
             end
           end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} preceded by an ensure" do
      source = <<~RUBY
           def a_method
           ensure
             #{conditional} condition_c
               do_something_extra
             end
           end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} preceded by a when" do
      source = <<~RUBY
           case field
           when value
             #{conditional} condition_c
               do_something_extra
             end
           end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} followed by an end" do
      source = <<~RUBY
          class Foo

            #{conditional} condition
              do_something
            end
          end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} followed by an else" do
      source = <<~RUBY
          #{conditional} condition_a
            #{conditional} condition_b
              do_something
            end
          else
            do_something_extra
          end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} followed by a when" do
      source = <<~RUBY
          case
          when condition_a
            #{conditional} condition_b
              do_something
            end
          when condition_c
            do_something_extra
          end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} followed by an elsif" do
      source = <<~RUBY
          if condition_a
            #{conditional} condition_b
              do_something
            end
          elsif condition_c
            do_something_extra
          end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{conditional} followed by a rescue" do
      source = <<~RUBY
            def a_method
              #{conditional} condition
                do_something
              end
              rescue
                do_something_extra
            end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end

    it "autocorrects #{conditional} without line break before" do
      source = <<~RUBY
          do_something
          #{conditional} condition
            do_something_more
          end
      RUBY
      autocorrected = autocorrect_source(source)

      expected_source = <<~RUBY
          do_something

          #{conditional} condition
            do_something_more
          end
      RUBY
      expect(autocorrected).to eql(expected_source)
    end

    it "autocorrects #{conditional} without line break after" do
      source = <<~RUBY
          #{conditional} condition
            do_something
          end
          do_something_more
      RUBY
      autocorrected = autocorrect_source(source)

      expected_source = <<~RUBY
          #{conditional} condition
            do_something
          end

          do_something_more
      RUBY
      expect(autocorrected).to eql(expected_source)
    end

    it "autocorrects #{conditional} without line break before and after" do
      source = <<~RUBY
          do_something
          #{conditional} condition
            do_something_more
          end
          do_something_extra
      RUBY
      autocorrected = autocorrect_source(source)

      expected_source = <<~RUBY
          do_something

          #{conditional} condition
            do_something_more
          end

          do_something_extra
      RUBY
      expect(autocorrected).to eql(expected_source)
    end
  end

  %w[if unless].each do |example|
    it_behaves_like 'examples with conditional', example
  end

  it "doesn't flag violation for if with elsif" do
    source = <<~RUBY
          if condition
            do_something
          elsif another_condition
            do_something_more
          end
    RUBY
    inspect_source(source)

    expect(cop.offenses).to be_empty
  end
end
