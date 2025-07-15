# frozen_string_literal: true

require 'yaml'

module Support
  module JsonbColumnValidation
    TODO_YAML = File.join(__dir__, 'jsonb_column_validation_todo.yml')

    module_function

    def todo?(model, column)
      @todo ||= YAML.load_file(TODO_YAML).to_set # rubocop:disable Gitlab/PredicateMemoization -- @todo is never `nil` or `false`.
      @todo.include?("#{model.name}##{column}")
    end
  end
end

# Checks whether JSONB columns are validated via JsonSchemaValidator.
#
# These checks are skipped in FOSS specs because they produce false positives,
# as the models are missing their EE extensions, including their validations.
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195456#note_2601197778
#
# See https://docs.gitlab.com/development/migration_style_guide/#storing-json-in-database
#
# Parameter:
# - model: Model class
# - jsonb_column: List of JSONB columns
RSpec.shared_examples 'Model validates JSONB columns' do |model, jsonb_columns|
  jsonb_columns.each do |column|
    context "with JSONB column #{column}" do
      let(:json_schema_validator) do
        model.validators_on(column).find { |validator| validator.is_a?(JsonSchemaValidator) }
      end

      it 'validates via JsonSchemaValidator' do
        pending 'Still a TODO' if Support::JsonbColumnValidation.todo?(model, column)

        docs_reference = 'See https://docs.gitlab.com/development/migration_style_guide/#storing-json-in-database.'
        expect(json_schema_validator).to be_present,
          "This JSONB column is missing schema validation. #{docs_reference}"
      end
    end
  end
end

RSpec.shared_context 'with JSONB validated columns' do # rubocop:disable RSpec/SharedContext -- We cannot include `shared_examples` conditionally based on `type: :model`
  model = described_class
  jsonb_columns = \
    model &&
    model < ApplicationRecord &&
    model.name && # skip unnamed/anonymous models
    !model.abstract_class? &&
    !model.table_name&.start_with?('_test') && # skip test models that define the tables in specs
    model.columns.select { |c| c.type == :jsonb }.map(&:name).map(&:to_sym)

  if jsonb_columns && jsonb_columns.any?
    include_examples 'Model validates JSONB columns', described_class, jsonb_columns
  end
end
