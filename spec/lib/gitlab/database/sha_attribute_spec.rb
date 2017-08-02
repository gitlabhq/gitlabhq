require 'spec_helper'

describe Gitlab::Database::ShaAttribute do
  let(:sha) do
    '9a573a369a5bfbb9a4a36e98852c21af8a44ea8b'
  end

  let(:binary_sha) do
    [sha].pack('H*')
  end

  let(:binary_from_db) do
    if Gitlab::Database.postgresql?
      "\\x#{sha}"
    else
      binary_sha
    end
  end

  let(:attribute) { described_class.new }

  describe '#type_cast_from_database' do
    it 'converts the binary SHA to a String' do
      expect(attribute.type_cast_from_database(binary_from_db)).to eq(sha)
    end
  end

  describe '#type_cast_for_database' do
    it 'converts a SHA String to binary data' do
      expect(attribute.type_cast_for_database(sha).to_s).to eq(binary_sha)
    end
  end
end
