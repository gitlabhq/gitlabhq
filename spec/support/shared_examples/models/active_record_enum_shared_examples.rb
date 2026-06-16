# frozen_string_literal: true

RSpec.shared_examples 'having unique enum values' do
  described_class.defined_enums.each do |name, enum|
    it "has unique values in #{name.inspect}" do
      duplicated = enum.group_by(&:last).select { |key, value| value.size > 1 }

      duplicated_values = duplicated.values.map { |value| Hash[value] }

      expect(duplicated).to be_empty,
        "Duplicated values detected: #{duplicated_values}"
    end
  end
end

RSpec.shared_examples 'having enum with nil value' do
  it 'has enum with nil value' do
    subject.public_send("#{attr_value}!")

    expect(subject.public_send("#{attr}_for_database")).to be_nil
    expect(subject.public_send("#{attr}?")).to be(true)
    expect(subject.class.public_send(attr_value)).to eq([subject])
  end
end
