# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Build::Port do
  subject { described_class.new(port) }

  context 'when port is defined as an integer' do
    let(:port) { 80 }

    it 'populates the object' do
      expect(subject.number).to eq 80
      expect(subject.protocol).to eq described_class::DEFAULT_PORT_PROTOCOL
      expect(subject.name).to eq described_class::DEFAULT_PORT_NAME
    end
  end

  context 'when port is defined as hash' do
    let(:port) { { number: 80, protocol: 'https', name: 'port_name' } }

    it 'populates the object' do
      expect(subject.number).to eq 80
      expect(subject.protocol).to eq 'https'
      expect(subject.name).to eq 'port_name'
    end
  end
end
