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

  context 'when using dynamic fields with Symbol' do
    let(:default_error_message) { 'Exactly one of group, project must be present' }
    let(:klass) do
      Class.new(ApplicationRecord) do
        self.table_name = '_test_exactly_one_present'

        def self.name
          'TestExactlyOnePresent'
        end

        belongs_to :group, optional: true
        belongs_to :project, optional: true
        belongs_to :organization, class_name: 'Organizations::Organization', optional: true

        validates_with ExactlyOnePresentValidator, fields: :dynamic_fields

        def dynamic_fields
          %w[group project]
        end
      end
    end

    it 'uses the method to resolve fields' do
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
  end

  context 'when using dynamic fields with private method Symbol' do
    let(:default_error_message) { 'Exactly one of title, color must be present' }
    let(:klass) do
      Class.new(ApplicationRecord) do
        self.table_name = '_test_exactly_one_present'

        def self.name
          'TestExactlyOnePresent'
        end

        validates_with ExactlyOnePresentValidator, fields: :private_dynamic_fields

        private

        def private_dynamic_fields
          %w[title color]
        end
      end
    end

    it 'uses the private method to resolve fields' do
      instance_object = klass.new

      expect(instance_object.valid?).to be_falsey
      expect(instance_object.errors.messages).to eq(base: [default_error_message])
    end

    it 'validates if exactly one field is present' do
      instance_object = klass.new(title: 'My Label')

      expect(instance_object.valid?).to be_truthy
    end
  end

  context 'when using dynamic fields with non-existent Symbol' do
    let(:invalid_klass) do
      Class.new(ApplicationRecord) do
        self.table_name = '_test_exactly_one_present'

        def self.name
          'TestExactlyOnePresent'
        end

        validates_with ExactlyOnePresentValidator, fields: :non_existent_method
      end
    end

    it 'raises an ArgumentError' do
      instance_object = invalid_klass.new

      expect do
        instance_object.valid?
      end.to raise_error(ArgumentError, 'Unknown :fields method non_existent_method')
    end
  end

  context 'when using dynamic fields with Proc' do
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

        validates_with ExactlyOnePresentValidator, fields: -> { %w[group project organization] }
      end
    end

    it 'uses the Proc to resolve fields' do
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
  end

  context 'when using dynamic fields with Proc that returns different fields based on record state' do
    let(:klass) do
      Class.new(ApplicationRecord) do
        self.table_name = '_test_exactly_one_present'

        def self.name
          'TestExactlyOnePresent'
        end

        belongs_to :group, optional: true
        belongs_to :project, optional: true

        validates_with ExactlyOnePresentValidator, fields: -> {
          title.present? ? %w[group project] : %w[title color]
        }
      end
    end

    it 'uses different fields based on record state' do
      instance_object = klass.new(title: 'My Label')

      expect(instance_object.valid?).to be_falsey
      expect(instance_object.errors.messages).to eq(base: ['Exactly one of group, project must be present'])
    end

    it 'validates with the correct fields' do
      instance_object = klass.new(title: 'My Label', group: group)

      expect(instance_object.valid?).to be_truthy
    end

    it 'uses alternative fields when title is not present' do
      instance_object = klass.new

      expect(instance_object.valid?).to be_falsey
      expect(instance_object.errors.messages).to eq(base: ['Exactly one of title, color must be present'])
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

  context 'when fields is not a Symbol, Array nor Proc' do
    let(:invalid_klass) do
      Class.new(ApplicationRecord) do
        self.table_name = '_test_exactly_one_present'

        def self.name
          'TestExactlyOnePresent'
        end

        validates_with ExactlyOnePresentValidator, fields: 'invalid_string'
      end
    end

    it 'raises an ArgumentError' do
      instance_object = invalid_klass.new

      expect do
        instance_object.valid?
      end.to raise_error(ArgumentError, 'Unknown :fields option type String')
    end
  end
end
