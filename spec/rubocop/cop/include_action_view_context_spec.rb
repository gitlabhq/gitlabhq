# frozen_string_literal: true

require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../rubocop/cop/include_action_view_context'

describe RuboCop::Cop::IncludeActionViewContext do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'when `ActionView::Context` is included' do
    let(:source) { 'include ActionView::Context' }
    let(:correct_source) { 'include ::Gitlab::ActionViewOutput::Context' }

    it 'registers an offense' do
      inspect_source(source)

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([1])
        expect(cop.highlights).to eq(['ActionView::Context'])
      end
    end

    it 'autocorrects to the right version' do
      autocorrected = autocorrect_source(source)

      expect(autocorrected).to eq(correct_source)
    end
  end

  context 'when `ActionView::Context` is not included' do
    it 'registers no offense' do
      inspect_source('include Context')

      aggregate_failures do
        expect(cop.offenses.size).to eq(0)
      end
    end
  end
end
