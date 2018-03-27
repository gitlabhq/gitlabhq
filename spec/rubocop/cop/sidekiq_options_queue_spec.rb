require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../rubocop/cop/sidekiq_options_queue'

describe RuboCop::Cop::SidekiqOptionsQueue do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'registers an offense when `sidekiq_options` is used with the `queue` option' do
    inspect_source('sidekiq_options queue: "some_queue"')

    aggregate_failures do
      expect(cop.offenses.size).to eq(1)
      expect(cop.offenses.map(&:line)).to eq([1])
      expect(cop.highlights).to eq(['queue: "some_queue"'])
    end
  end

  it 'does not register an offense when `sidekiq_options` is used with another option' do
    inspect_source('sidekiq_options retry: false')

    expect(cop.offenses).to be_empty
  end
end
