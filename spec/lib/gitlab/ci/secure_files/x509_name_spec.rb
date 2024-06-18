# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::SecureFiles::X509Name do
  describe '.parse' do
    it 'parses an X509Name object into a hash format' do
      sample = OpenSSL::X509::Name.new([
        ['C', 'Test Country'],
                                         ['O', 'Test Org Name'],
                                         ['OU', 'Test Org Unit'],
                                         ['CN', 'Test Common Name'],
                                         ['UID', 'Test UID']
      ])

      parsed_sample = described_class.parse(sample)

      expect(parsed_sample["C"]).to eq('Test Country')
      expect(parsed_sample["O"]).to eq('Test Org Name')
      expect(parsed_sample["OU"]).to eq('Test Org Unit')
      expect(parsed_sample["CN"]).to eq('Test Common Name')
      expect(parsed_sample["UID"]).to eq('Test UID')
    end

    it 'returns an empty hash when an error occurs' do
      parsed_sample = described_class.parse('unexpectedinput')
      expect(parsed_sample).to eq({})
    end
  end
end
