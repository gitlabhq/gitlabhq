# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExactlyOnePresentValidator, feature_category: :shared do
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  before_all do
    ApplicationRecord.connection.execute(
      <<~SQL
        CREATE TABLE IF NOT EXISTS _test_exactly_one_present (
          id BIGINT PRIMARY KEY,
          title VARCHAR(255),
          color VARCHAR(255),
          group_id BIGINT,
          project_id BIGINT,
          organization_id BIGINT
        );
      SQL
    )
  end

  context 'when validation is instantiated correctly' do
    context 'when validating ActiveRecord relations' do
      let(:default_error_message) { 'Exactly one of group, project, organization must be present' }
      let(:klass) do
        Class.new(ApplicationRecord) do
          self.table_name = '_test_exactly_one_present'

          def self.name
            'TestExactlyOnePresent'
          end

          belongs_to :group, optional: true
          belongs_to :project, optional: true
          belongs_to :organization, class_name: 'Organizations::Organization', optional: true

          validates_with ExactlyOnePresentValidator, fields: %w[group project organization]
        end
      end

      it 'raises an error if no fields are present' do
        instance_object = klass.new

        expect(instance_object.valid?).to be_falsey
        expect(instance_object.errors.messages).to eq(base: [default_error_message])
      end

      it 'validates if exactly one field is present' do
        instance_object = klass.new(project: project)

        expect(instance_object.valid?).to be_truthy
      end

      it 'raises an error if more than one field is present' do
        instance_object = klass.new(group: group, project: project)

        expect(instance_object.valid?).to be_falsey
        expect(instance_object.errors.messages).to eq(base: [default_error_message])
      end

      it 'ignores blank values when checking presence' do
        instance_object = klass.new(group: group, organization_id: '')

        expect(instance_object.valid?).to be_truthy
      end
    end

    context 'when validating Model fields' do
      let(:default_error_message) { 'Exactly one of title, color must be present' }
      let(:klass) do
        Class.new(ApplicationRecord) do
          self.table_name = '_test_exactly_one_present'

          def self.name
            'TestExactlyOnePresent'
          end

          validates_with ExactlyOnePresentValidator, fields: %w[title color]
        end
      end

      it 'raises an error if no fields are present' do
        instance_object = klass.new

        expect(instance_object.valid?).to be_falsey
        expect(instance_object.errors.messages).to eq(base: [default_error_message])
      end

      it 'validates if exactly one field is present' do
        instance_object = klass.new(title: 'My Label')

        expect(instance_object.valid?).to be_truthy
      end

      it 'raises an error if more than one field is present' do
        instance_object = klass.new(title: 'My Label', color: 'red')

        expect(instance_object.valid?).to be_falsey
        expect(instance_object.errors.messages).to eq(base: [default_error_message])
      end

      it 'ignores blank values when checking presence' do
        instance_object = klass.new(title: 'My Label', color: '')

        expect(instance_object.valid?).to be_truthy
      end
    end
  end

  context 'when using custom error_key option' do
    let(:default_error_message) { 'Exactly one of group, project, organization must be present' }
    let(:klass) do
      Class.new(ApplicationRecord) do
        self.table_name = '_test_exactly_one_present'

        def self.name
          'TestExactlyOnePresent'
        end

        belongs_to :group, optional: true
        belongs_to :project, optional: true
        belongs_to :organization, class_name: 'Organizations::Organization', optional: true

        validates_with ExactlyOnePresentValidator, fields: %w[group project organization], error_key: :custom_error_key
      end
    end

    it 'adds error to the specified error key' do
      instance_object = klass.new

      expect(instance_object.valid?).to be_falsey
      expect(instance_object.errors.messages).to eq(custom_error_key: [default_error_message])
    end
  end

  context 'when using custom message option' do
    let(:klass) do
      Class.new(ApplicationRecord) do
        self.table_name = '_test_exactly_one_present'

        def self.name
          'TestExactlyOnePresent'
        end

        belongs_to :group, optional: true
        belongs_to :project, optional: true

        validates_with ExactlyOnePresentValidator, fields: %w[group project],
          message: ->(fields) { "Custom validation message with #{fields.join(', ')}" }
      end
    end

    it 'uses the custom error message' do
      instance_object = klass.new

      expect(instance_object.valid?).to be_falsey
      expect(instance_object.errors.messages).to eq(base: ['Custom validation message with group, project'])
    end
  end

  context 'when using both error_key and message options' do
    let(:klass) do
      Class.new(ApplicationRecord) do
        self.table_name = '_test_exactly_one_present'

        def self.name
          'TestExactlyOnePresent'
        end

        belongs_to :group, optional: true
        belongs_to :project, optional: true

        validates_with ExactlyOnePresentValidator, fields: %w[group project],
          error_key: :custom_error_key, message: 'Custom validation message'
      end
    end

    it 'uses both custom error key and message' do
      instance_object = klass.new

      expect(instance_object.valid?).to be_falsey
      expect(instance_object.errors.messages).to eq(custom_error_key: ['Custom validation message'])
    end
  end

  context 'when validation is missing the fields parameter' do
    let(:invalid_klass) do
      Class.new(ApplicationRecord) do
        self.table_name = '_test_exactly_one_present'

        def self.name
          'TestExactlyOnePresent'
        end

        validates_with ExactlyOnePresentValidator
      end
    end

    it 'raises an error' do
      expect do
        invalid_klass.new
      end.to raise_error(RuntimeError, 'ExactlyOnePresentValidator: :fields options are required')
    end
  end
end
