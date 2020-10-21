# frozen_string_literal: true

require 'fast_spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/rspec/timecop_travel'

RSpec.describe RuboCop::Cop::RSpec::TimecopTravel, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'when calling Timecop.travel' do
    let(:source) do
      <<~SRC
      Timecop.travel(1.day.ago) { create(:issue) }
      SRC
    end

    let(:corrected_source) do
      <<~SRC
      travel_to(1.day.ago) { create(:issue) }
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
      Timecop.freeze { create(:issue) }
      SRC
    end

    it 'does not register an offence' do
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end
  end
end
