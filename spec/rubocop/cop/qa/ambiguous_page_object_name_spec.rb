# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../rubocop/cop/qa/ambiguous_page_object_name'

RSpec.describe RuboCop::Cop::QA::AmbiguousPageObjectName do
  let(:source_file) { 'qa/page.rb' }

  subject(:cop) { described_class.new }

  context 'in a QA file' do
    before do
      allow(cop).to receive(:in_qa_file?).and_return(true)
    end

    it "registers an offense for pages named `page`" do
      expect_offense(<<-RUBY)
      Page::Layout::Bar.perform do |page|
                                    ^^^^ Don't use 'page' as a name for a Page Object. Use `bar` instead.
        expect(page).to have_performance_bar
        expect(page).to have_detailed_metrics
      end
      RUBY
    end

    it "doesnt offend if the page object is named otherwise" do
      expect_no_offenses(<<-RUBY)
        Page::Object.perform do |obj|
          obj.whatever
        end
      RUBY
    end
  end

  context 'outside of a QA file' do
    before do
      allow(cop).to receive(:in_qa_file?).and_return(false)
    end

    it "does not register an offense" do
      expect_no_offenses(<<-RUBY)
        Page::Object.perform do |page|
          page.do_something
        end
      RUBY
    end
  end
end
