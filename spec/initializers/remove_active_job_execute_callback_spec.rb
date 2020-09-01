# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ActiveJob execute callback' do
  it 'is removed in test environment' do
    expect(ActiveJob::Callbacks.singleton_class.__callbacks[:execute].send(:chain).size).to eq(0)
  end
end
