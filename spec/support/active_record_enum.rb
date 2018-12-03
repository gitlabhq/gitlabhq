# frozen_string_literal: true

shared_examples 'Unique enum values' do
  described_class.defined_enums.each do |name, hash|
    it "has unique values in #{name}" do
      expect(hash.values).to contain_exactly(*hash.values.uniq)
    end
  end
end
