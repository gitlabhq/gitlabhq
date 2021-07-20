# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::Ci::JobRequest::Port do
  let(:port) { double(number: 80, protocol: 'http', name: 'name')}
  let(:entity) { described_class.new(port) }

  subject { entity.as_json }

  it 'returns the port number' do
    expect(subject[:number]).to eq 80
  end

  it 'returns if the port protocol' do
    expect(subject[:protocol]).to eq 'http'
  end

  it 'returns the port name' do
    expect(subject[:name]).to eq 'name'
  end
end
