# frozen_string_literal: true

require 'spec_helper'

describe ProviderRepoSerializer do
  it 'represents ProviderRepoEntity entities' do
    expect(described_class.entity_class).to eq(ProviderRepoEntity)
  end
end
