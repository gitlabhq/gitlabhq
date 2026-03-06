# frozen_string_literal: true

RSpec.shared_examples 'work item type configuration' do |method, cases|
  describe "##{method}" do
    cases.each do |base_type, expected_value|
      context "for #{base_type}" do
        it "returns #{expected_value}" do
          type = described_class.find_by_type(base_type)

          expect(type.send(method)).to be(expected_value)
        end
      end
    end
  end
end
