require 'spec_helper'
describe Gitlab::Utils::MergeHash do
  describe '.crush' do
    it 'can flatten a hash to each element' do
      input = { hello: "world", this: { crushes: ["an entire", "hash"] } }
      expected_result = [:hello, "world", :this, :crushes, "an entire", "hash"]

      expect(described_class.crush(input)).to eq(expected_result)
    end
  end

  describe '.elements' do
    it 'deep merges an array of elements' do
      input = [{ hello: ["world"] },
               { hello: "Everyone" },
               { hello: { greetings: ['Bonjour', 'Hello', 'Hallo', 'Dzień dobry'] } },
               "Goodbye", "Hallo"]
      expected_output = [
        {
          hello:
            [
              "world",
              "Everyone",
              { greetings: ['Bonjour', 'Hello', 'Hallo', 'Dzień dobry'] }
            ]
        },
        "Goodbye"
      ]

      expect(described_class.merge(input)).to eq(expected_output)
    end
  end
end
