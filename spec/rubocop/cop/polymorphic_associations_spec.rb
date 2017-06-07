require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/polymorphic_associations'

describe RuboCop::Cop::PolymorphicAssociations do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'inside the app/models directory' do
    it 'registers an offense when polymorphic: true is used' do
      allow(cop).to receive(:in_model?).and_return(true)

      inspect_source(cop, 'belongs_to :foo, polymorphic: true')

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([1])
      end
    end
  end

  context 'outside the app/models directory' do
    it 'does nothing' do
      allow(cop).to receive(:in_model?).and_return(false)

      inspect_source(cop, 'belongs_to :foo, polymorphic: true')

      expect(cop.offenses).to be_empty
    end
  end
end
