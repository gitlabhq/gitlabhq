# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AnyFieldValidator do
  context 'when validation is instantiated correctly' do
    let(:validated_class) do
      Class.new(ApplicationRecord) do
        self.table_name = 'vulnerabilities'

        validates_with AnyFieldValidator, fields: %w[title description]
      end
    end

    it 'raises an error if no fields are defined' do
      validated_object = validated_class.new

      expect(validated_object.valid?).to be_falsey
      expect(validated_object.errors.messages)
      .to eq(base: ["At least one field of %{one_of_required_fields} must be present" %
        { one_of_required_fields: %w[title description] }])
    end

    it 'validates if only one field is present' do
      validated_object = validated_class.new(title: 'Vulnerability title')

      expect(validated_object.valid?).to be_truthy
    end
  end

  context 'when validation is missing the fields parameter' do
    let(:invalid_class) do
      Class.new(ApplicationRecord) do
        self.table_name = 'vulnerabilities'

        validates_with AnyFieldValidator
      end
    end

    it 'raises an error' do
      expect { invalid_class.new }.to raise_error(RuntimeError)
    end
  end
end
