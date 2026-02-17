# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DefaultBranch do
  it 'returns main' do
    expect(described_class.value).to eq('main')
  end
end
