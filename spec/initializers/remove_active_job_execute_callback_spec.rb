# frozen_string_literal: true

require 'fast_spec_helper'
require 'active_job/callbacks'
require 'active_job'

RSpec.describe 'ActiveJob execute callback' do
  it 'is removed in test environment' do
    expect(ActiveJob::Callbacks.singleton_class.__callbacks[:execute].send(:chain).size).to eq(0)
  end
end
