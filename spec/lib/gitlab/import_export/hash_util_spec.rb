# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::HashUtil do
  let(:stringified_array) { [{ 'test' => 1 }] }
  let(:stringified_array_with_date) { [{ 'test_date' => '2016-04-06 06:17:44 +0200' }] }

  describe '.deep_symbolize_array!' do
    it 'symbolizes keys' do
      expect { described_class.deep_symbolize_array!(stringified_array) }.to change {
        stringified_array.first.keys.first
      }.from('test').to(:test)
    end
  end

  describe '.deep_symbolize_array_with_date!' do
    it 'symbolizes keys' do
      expect { described_class.deep_symbolize_array_with_date!(stringified_array_with_date) }.to change {
        stringified_array_with_date.first.keys.first
      }.from('test_date').to(:test_date)
    end

    it 'transforms date strings into Time objects' do
      expect { described_class.deep_symbolize_array_with_date!(stringified_array_with_date) }.to change {
        stringified_array_with_date.first.values.first.class
      }.from(String).to(ActiveSupport::TimeWithZone)
    end
  end
end
