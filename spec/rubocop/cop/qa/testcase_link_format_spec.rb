# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../rubocop/cop/qa/testcase_link_format'

RSpec.describe RuboCop::Cop::QA::TestcaseLinkFormat do
  let(:source_file) { 'qa/page.rb' }
  let(:msg) { 'Testcase link format incorrect. Please link a test case from the GitLab project. See: https://docs.gitlab.com/ee/development/testing_guide/end_to_end/best_practices.html#link-a-test-to-its-test-case.' }

  subject(:cop) { described_class.new }

  context 'in a QA file' do
    before do
      allow(cop).to receive(:in_qa_file?).and_return(true)
    end

    it "registers an offense for a testcase link for an issue" do
      node = "it 'another test', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/issues/557' do"

      expect_offense(<<-RUBY, node: node, msg: msg)
        %{node}
        ^{node} %{msg}
        end
      RUBY
    end

    it "registers an offense for a testcase link for the wrong project" do
      node = "it 'another test', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/2455' do"

      expect_offense(<<-RUBY, node: node, msg: msg)
        %{node}
        ^{node} %{msg}
        end
      RUBY
    end

    it "doesnt offend if testcase link is correct" do
      expect_no_offenses(<<-RUBY)
        it 'some test', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348312' do
        end
      RUBY
    end
  end
end
