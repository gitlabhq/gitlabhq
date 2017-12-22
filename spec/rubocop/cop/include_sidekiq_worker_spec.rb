require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../rubocop/cop/include_sidekiq_worker'

describe RuboCop::Cop::IncludeSidekiqWorker do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'when `Sidekiq::Worker` is included' do
    let(:source) { 'include Sidekiq::Worker' }
    let(:correct_source) { 'include ApplicationWorker' }

    it 'registers an offense ' do
      inspect_source(source)

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([1])
        expect(cop.highlights).to eq(['Sidekiq::Worker'])
      end
    end

    it 'autocorrects to the right version' do
      autocorrected = autocorrect_source(source)

      expect(autocorrected).to eq(correct_source)
    end
  end
end
