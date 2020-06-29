# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require_relative '../../../../rubocop/cop/api/grape_api_instance'

RSpec.describe RuboCop::Cop::API::GrapeAPIInstance do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'adds an offense when inheriting from Grape::API' do
    inspect_source(<<~CODE)
      class SomeAPI < Grape::API
      end
    CODE

    expect(cop.offenses.size).to eq(1)
  end

  it 'does not add an offense when inheriting from Grape::API::Instance' do
    inspect_source(<<~CODE)
      class SomeAPI < Grape::API::Instance
      end
    CODE

    expect(cop.offenses.size).to be_zero
  end
end
