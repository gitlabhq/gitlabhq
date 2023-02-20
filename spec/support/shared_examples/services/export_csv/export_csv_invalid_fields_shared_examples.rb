# frozen_string_literal: true

RSpec.shared_examples 'a service that returns invalid fields from selection' do
  describe '#invalid_fields' do
    it 'returns invalid fields from selection' do
      fields = %w[title invalid_1 invalid_2]

      service = described_class.new(WorkItem.all, project, fields)

      expect(service.invalid_fields).to eq(%w[invalid_1 invalid_2])
    end
  end
end
