# frozen_string_literal: true

require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/qa/element_with_pattern'

describe RuboCop::Cop::QA::ElementWithPattern do
  include CopHelper

  let(:source_file) { 'qa/page.rb' }

  subject(:cop) { described_class.new }

  context 'in a QA file' do
    before do
      allow(cop).to receive(:in_qa_file?).and_return(true)
    end

    it "registers an offense for elements with a pattern" do
      expect_offense(<<-RUBY)
      view 'app/views/shared/groups/_search_form.html.haml' do
        element :groups_filter, 'search_field_tag :filter'
                                ^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't use a pattern for element, create a corresponding `data-qa-selector=groups_filter` instead.
        element :groups_filter_placeholder, /Search by name/
                                             ^^^^^^^^^^^^^^ Don't use a pattern for element, create a corresponding `data-qa-selector=groups_filter_placeholder` instead.
      end
      RUBY
    end

    it "does not register an offense for element without a pattern" do
      expect_no_offenses(<<-RUBY)
      view 'app/views/shared/groups/_search_form.html.haml' do
        element :groups_filter
        element :groups_filter_placeholder
      end
      RUBY

      expect_no_offenses(<<-RUBY)
      view 'app/views/shared/groups/_search_form.html.haml' do
        element :groups_filter, required: true
        element :groups_filter_placeholder, required: false
      end
      RUBY
    end
  end

  context 'outside of a migration spec file' do
    it "does not register an offense" do
      expect_no_offenses(<<-RUBY)
        describe 'foo' do
          let(:user) { create(:user) }
        end
      RUBY
    end
  end
end
