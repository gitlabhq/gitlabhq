# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Type::JsonbFloat, feature_category: :database do
  describe '#cast' do
    using RSpec::Parameterized::TableSyntax
    where(:value, :expected_value) do
      1.5           | 1.5
      '1.5'         | 1.5
      1             | 1.0
      '1'           | 1.0
      -1.5          | -1.5
      '-1.5'        | -1.5
      '0.0'         | 0.0
      0             | 0.0
      'not_float'   | 'not_float'
      ''            | ''
      nil           | nil
      []            | []
      {}            | {}
      true          | true
      false         | false
    end

    with_them do
      it "handles #{params} correctly" do
        expect(described_class.new.cast(value)).to eq(expected_value)
      end
    end
  end
end
