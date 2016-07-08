require 'spec_helper'

describe Gitlab::Import::Result, lib: true do
  subject(:result) { described_class.new }

  it 'success when errors is empty' do
    expect(result).to be_success
    expect(result).not_to be_failed
  end

  it 'failed when errors is not empty' do
    result.errors << 'Something goes wrong'

    expect(result).to be_failed
    expect(result).not_to be_success
  end
end
