# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe 'JSON validator patch' do
  using RSpec::Parameterized::TableSyntax

  let(:schema) { '{"format": "string"}' }

  subject { JSON::Validator.validate(schema, data) }

  context 'with invalid JSON' do
    where(:data) do
      [
        'https://example.com',
        '/tmp/test.txt'
      ]
    end

    with_them do
      it 'does not attempt to open a file or URI' do
        allow(File).to receive(:read).and_call_original
        allow(URI).to receive(:open).and_call_original
        expect(File).not_to receive(:read).with(data)
        expect(URI).not_to receive(:open).with(data)
        expect(subject).to be true
      end
    end
  end

  context 'with valid JSON' do
    let(:data) { %({ 'somekey': 'value' }) }

    it 'validates successfully' do
      expect(subject).to be true
    end
  end
end
