# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/qa/selector_usage'

RSpec.describe RuboCop::Cop::QA::SelectorUsage do
  shared_examples 'non-qa file usage' do
    it 'reports an offense' do
      expect_offense(<<-RUBY)
        find('#{selector}').click
             #{'^' * (selector.size + 2)} Do not use `#{selector}` as this is reserved for the end-to-end specs. Use a different selector or a data-testid instead.
      RUBY
    end
  end

  context 'in a QA file' do
    before do
      allow(cop).to receive(:in_qa_file?).and_return(true)
    end

    it 'has no error' do
      expect_no_offenses(<<-RUBY)
        has_element?('[data-qa-selector="my_selector"]')
      RUBY
    end
  end

  context 'outside of QA' do
    before do
      allow(cop).to receive(:in_qa_file?).and_return(false)
      allow(cop).to receive(:in_spec?).and_return(true)
    end

    context 'data-qa-selector' do
      let(:selector) { '[data-qa-selector="my_selector"]' }

      it_behaves_like 'non-qa file usage'
    end

    context 'qa class' do
      let(:selector) { '.qa-selector' }

      it_behaves_like 'non-qa file usage'
    end
  end
end
