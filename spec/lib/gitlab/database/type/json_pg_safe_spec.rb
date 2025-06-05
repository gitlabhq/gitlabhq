# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Type::JsonPgSafe do
  let(:type) { described_class.new }

  describe '#serialize' do
    using RSpec::Parameterized::TableSyntax

    subject { type.serialize(value) }

    where(:value, :json) do
      nil                            | nil
      1                              | '1'
      1.0                            | '1.0'
      "str\0ing\u0000"               | '"string"'
      ["\0arr", "a\u0000y"]          | '["arr","ay"]'
      { "key\0" => "value\u0000\0" } | '{"key":"value"}'
      { "key" => "value\\u0000\0" }  | '{"key":"value\\\\u0000"}'
    end

    with_them do
      it { is_expected.to eq(json) }
    end

    context 'when replace_with is provided' do
      let(:type) { described_class.new(replace_with: "\\u0000") }

      subject(:serialize) { type.serialize({ 'foo' => "value\u0000" }) }

      it 'replaces the unicode null characters with provided value' do
        expect(serialize).to eq('{"foo":"value\\u0000"}')
      end
    end
  end
end
