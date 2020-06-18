# frozen_string_literal: true

RSpec::Matchers.define :validate_jsonb_schema do |jsonb_columns|
  match do |actual|
    next true if jsonb_columns.blank?

    expect(actual.validators).to include(a_kind_of(JsonSchemaValidator))
  end

  failure_message do
    <<~FAILURE_MESSAGE
      Expected #{actual.name} to validate the schema of #{jsonb_columns.join(', ')}.

      Use JsonSchemaValidator in your model when using a jsonb column.
      See doc/development/migration_style_guide.html#storing-json-in-database for more information.

      To fix this, please add `validates :#{jsonb_columns.first}, json_schema: { filename: "filename" }` in your model file, for example:

      class #{actual.name}
        validates :#{jsonb_columns.first}, json_schema: { filename: "filename" }
      end
    FAILURE_MESSAGE
  end
end
