# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Type::JsonbInteger, feature_category: :database do
  describe '#cast' do
    using RSpec::Parameterized::TableSyntax
    where(:value, :expected_value) do
      1       | 1
      '1'     | 1
      -1      | -1
      '-1'    | -1
      '42'    | 42
      42      | 42
      '0'     | 0
      0       | 0
      'abc'   | 'abc'
      ''      | ''
      nil     | nil
      []      | []
      {}      | {}
      true    | true
      false   | false
    end

    with_them do
      it "handles #{params} correctly" do
        expect(described_class.new.cast(value)).to eq(expected_value)
      end
    end
  end
end
