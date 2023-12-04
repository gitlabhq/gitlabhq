# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../tooling/lib/tooling/helpers/duration_formatter'

module TestModule
  class MockClass
    include Tooling::Helpers::DurationFormatter
  end
end

RSpec.describe Tooling::Helpers::DurationFormatter, feature_category: :tooling do
  subject(:result) { TestModule::MockClass.new.readable_duration(argument) }

  context 'when duration is less than 1 second' do
    let(:argument) { 0.11111 }

    it { expect(result).to eq('0.11 second') }
  end

  context 'when duration is less than 60 seconds' do
    let(:argument) { 5.2 }

    it { expect(result).to eq('5.2 seconds') }
  end

  context 'when duration is exactly 60 seconds' do
    let(:argument) { 60 }

    it { expect(result).to eq('1 minute') }
  end

  context 'when duration is 60.02 seconds' do
    let(:argument) { 60.02 }

    it { expect(result).to eq('1 minute 0.02 second') }
  end

  context 'when duration is 65.5 seconds' do
    let(:argument) { 65.5 }

    it { expect(result).to eq('1 minute 5.5 seconds') }
  end

  context 'when duration is more than 2 minutes' do
    let(:argument) { 120.5 }

    it { expect(result).to eq('2 minutes 0.5 second') }
  end
end
