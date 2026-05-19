# frozen_string_literal: true

RSpec.shared_examples 'an event with schema' do |valid_data:, missing_required:, invalid_types:|
  describe '#schema' do
    context 'with valid data' do
      it 'initializes without error' do
        expect { described_class.new(data: valid_data) }.not_to raise_error
      end
    end

    context 'with missing required properties' do
      missing_required.each do |field|
        it "raises an error when #{field} is missing" do
          expect { described_class.new(data: valid_data.except(field)) }
            .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
        end
      end
    end

    context 'with invalid property types' do
      invalid_types.each do |field, invalid_value|
        it "raises an error when #{field} has an invalid type" do
          expect { described_class.new(data: valid_data.merge(field => invalid_value)) }
            .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
        end
      end
    end
  end
end
