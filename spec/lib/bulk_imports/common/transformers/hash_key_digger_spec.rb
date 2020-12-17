# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Transformers::HashKeyDigger do
  describe '#transform' do
    it 'when the key_path is an array' do
      data = { foo: { bar: :value } }
      key_path = %i[foo bar]
      transformed = described_class.new(key_path: key_path).transform(nil, data)

      expect(transformed).to eq(:value)
    end

    it 'when the key_path is not an array' do
      data = { foo: { bar: :value } }
      key_path = :foo
      transformed = described_class.new(key_path: key_path).transform(nil, data)

      expect(transformed).to eq({ bar: :value })
    end

    it "when the data is not a hash" do
      expect { described_class.new(key_path: nil).transform(nil, nil) }
        .to raise_error(ArgumentError, "Given data must be a Hash")
    end
  end
end
