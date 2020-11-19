# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Experimentation::GroupTypes do
  it 'defines a GROUP_CONTROL constant' do
    expect(described_class.const_defined?(:GROUP_CONTROL)).to be_truthy
  end

  it 'defines a GROUP_EXPERIMENTAL constant' do
    expect(described_class.const_defined?(:GROUP_EXPERIMENTAL)).to be_truthy
  end
end
