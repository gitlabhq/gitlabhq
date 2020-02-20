# frozen_string_literal: true

RSpec.shared_examples 'having unique enum values' do
  described_class.defined_enums.each do |name, enum|
    it "has unique values in #{name.inspect}" do
      duplicated = enum.group_by(&:last).select { |key, value| value.size > 1 }

      expect(duplicated).to be_empty,
        "Duplicated values detected: #{duplicated.values.map(&Hash.method(:[]))}"
    end
  end
end
