# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require_relative '../../../../rubocop/cop/rspec/modify_sidekiq_middleware'

RSpec.describe RuboCop::Cop::RSpec::ModifySidekiqMiddleware, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  let(:source) do
    <<~SRC
    Sidekiq::Testing.server_middleware do |chain|
      chain.add(MyCustomMiddleware)
    end
    SRC
  end

  let(:corrected) do
    <<~SRC
    with_sidekiq_server_middleware do |chain|
      chain.add(MyCustomMiddleware)
    end
    SRC
  end

  it 'registers an offence' do
    inspect_source(source)

    expect(cop.offenses.size).to eq(1)
  end

  it 'can autocorrect the source' do
    expect(autocorrect_source(source)).to eq(corrected)
  end
end
