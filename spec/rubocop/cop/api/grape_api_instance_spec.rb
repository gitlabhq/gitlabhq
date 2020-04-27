# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require_relative '../../../support/helpers/expect_offense'
require_relative '../../../../rubocop/cop/api/grape_api_instance'

describe RuboCop::Cop::API::GrapeAPIInstance do
  include CopHelper
  include ExpectOffense

  subject(:cop) { described_class.new }

  it 'adds an offense when inheriting from Grape::API' do
    inspect_source(<<~CODE.strip_indent)
      class SomeAPI < Grape::API
      end
    CODE

    expect(cop.offenses.size).to eq(1)
  end

  it 'does not add an offense when inheriting from Grape::API::Instance' do
    inspect_source(<<~CODE.strip_indent)
      class SomeAPI < Grape::API::Instance
      end
    CODE

    expect(cop.offenses.size).to be_zero
  end
end
