# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../rubocop/cop/qa/duplicate_testcase_link'

RSpec.describe RuboCop::Cop::QA::DuplicateTestcaseLink do
  let(:source_file) { 'qa/page.rb' }

  subject(:cop) { described_class.new }

  context 'in a QA file' do
    before do
      allow(cop).to receive(:in_qa_file?).and_return(true)
    end

    it "registers an offense for a duplicate testcase link" do
      expect_offense(<<-RUBY)
        it 'some test', testcase: '/quality/test_cases/1892' do
        end
        it 'another test', testcase: '/quality/test_cases/1892' do
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't reuse the same testcase link in different tests. Replace one of `/quality/test_cases/1892`.
        end
      RUBY
    end

    it "doesnt offend if testcase link is unique" do
      expect_no_offenses(<<-RUBY)
        it 'some test', testcase: '/quality/test_cases/1893' do
        end
        it 'another test', testcase: '/quality/test_cases/1894' do
        end
      RUBY
    end
  end
end
