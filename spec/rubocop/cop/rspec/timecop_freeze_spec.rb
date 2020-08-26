# frozen_string_literal: true

require 'fast_spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/rspec/timecop_freeze'

RSpec.describe RuboCop::Cop::RSpec::TimecopFreeze, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'when calling Timecop.freeze' do
    let(:source) do
      <<~SRC
      Timecop.freeze(Time.current) { example.run }
      SRC
    end

    let(:corrected_source) do
      <<~SRC
      freeze_time(Time.current) { example.run }
      SRC
    end

    it 'registers an offence' do
      inspect_source(source)

      expect(cop.offenses.size).to eq(1)
    end

    it 'can autocorrect the source' do
      expect(autocorrect_source(source)).to eq(corrected_source)
    end
  end

  context 'when calling a different method on Timecop' do
    let(:source) do
      <<~SRC
      Timecop.travel(Time.current)
      SRC
    end

    it 'does not register an offence' do
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end
  end
end
