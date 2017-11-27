require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/line_break_after_guard_clauses'

describe RuboCop::Cop::LineBreakAfterGuardClauses do
  include CopHelper

  subject(:cop) { described_class.new }

  shared_examples 'examples with guard clause' do |title|
    %w[if unless].each do |conditional|
      it "flags violation for #{title} #{conditional} without line breaks" do
        source = <<~RUBY
          #{title} #{conditional} condition
          do_stuff
        RUBY
        inspect_source(cop, source)

        expect(cop.offenses.size).to eq(1)
        offense = cop.offenses.first

        expect(offense.line).to eq(1)
        expect(cop.highlights).to eq(["#{title} #{conditional} condition"])
        expect(offense.message).to eq('Add a line break after guard clauses')
      end

      it "doesn't flag violation for #{title} #{conditional} with line break" do
        source = <<~RUBY
          #{title} #{conditional} condition

          do_stuff
        RUBY
        inspect_source(cop, source)

        expect(cop.offenses).to be_empty
      end

      it "doesn't flag violation for #{title} #{conditional} on multiple lines without line break" do
        source = <<~RUBY
          #{conditional} condition
            #{title}
          end
          do_stuff
        RUBY
        inspect_source(cop, source)

        expect(cop.offenses).to be_empty
      end

      it "doesn't flag violation for #{title} #{conditional} without line breaks when followed by end keyword" do
        source = <<~RUBY
          def test
            #{title} #{conditional} condition
          end
        RUBY
        inspect_source(cop, source)

        expect(cop.offenses).to be_empty
      end

      it "doesn't flag violation for #{title} #{conditional} without line breaks when followed by elsif keyword" do
        source = <<~RUBY
          if model
            #{title} #{conditional} condition
          elsif
            do_something
          end
        RUBY
        inspect_source(cop, source)

        expect(cop.offenses).to be_empty
      end

      it "doesn't flag violation for #{title} #{conditional} without line breaks when followed by else keyword" do
        source = <<~RUBY
          if model
            #{title} #{conditional} condition
          else
            do_something
          end
        RUBY
        inspect_source(cop, source)

        expect(cop.offenses).to be_empty
      end

      it "doesn't flag violation for #{title} #{conditional} without line breaks when followed by when keyword" do
        source = <<~RUBY
          case model
            when condition_a
              #{title} #{conditional} condition
            when condition_b
              do_something
            end
        RUBY
        inspect_source(cop, source)

        expect(cop.offenses).to be_empty
      end

      it "doesn't flag violation for #{title} #{conditional} without line breaks when followed by rescue keyword" do
        source = <<~RUBY
          begin
            #{title} #{conditional} condition
          rescue StandardError
            do_something
          end
        RUBY
        inspect_source(cop, source)

        expect(cop.offenses).to be_empty
      end

      it "doesn't flag violation for #{title} #{conditional} without line breaks when followed by ensure keyword" do
        source = <<~RUBY
          def foo
            #{title} #{conditional} condition
          ensure
            do_something
          end
        RUBY
        inspect_source(cop, source)

        expect(cop.offenses).to be_empty
      end

      it "doesn't flag violation for #{title} #{conditional} without line breaks when followed by another guard clause" do
        source = <<~RUBY
          #{title} #{conditional} condition
          #{title} #{conditional} condition

          do_stuff
        RUBY
        inspect_source(cop, source)

        expect(cop.offenses).to be_empty
      end

      it "autocorrects #{title} #{conditional} guard clauses without line break" do
        source = <<~RUBY
          #{title} #{conditional} condition
          do_stuff
        RUBY
        autocorrected = autocorrect_source(cop, source)

        expected_source = <<~RUBY
          #{title} #{conditional} condition

          do_stuff
        RUBY
        expect(autocorrected).to eql(expected_source)
      end
    end
  end

  %w[return fail raise next break throw].each do |example|
    it_behaves_like 'examples with guard clause', example
  end
end
