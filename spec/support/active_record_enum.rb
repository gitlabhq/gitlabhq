# frozen_string_literal: true

shared_examples 'Unique enum values' do
  described_class.defined_enums.each do |name, hash|
    it "has unique values in #{name}" do
      duplicated = hash.group_by(&:last).select { |key, value| value.size > 1 }

      expect(duplicated).to be_empty,
        "Duplicated values detected: #{duplicated.values.map(&Hash.method(:[]))}"
    end
  end
end
