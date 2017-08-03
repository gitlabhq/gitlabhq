def schema_path(schema)
  schema_directory = "#{Dir.pwd}/spec/fixtures/api/schemas"
  "#{schema_directory}/#{schema}.json"
end

RSpec::Matchers.define :match_response_schema do |schema, **options|
  match do |response|
    @errors = JSON::Validator.fully_validate(schema_path(schema), response.body, options)

    @errors.empty?
  end

  failure_message do |response|
    "didn't match the schema defined by #{schema_path(schema)}" \
    " The validation errors were:\n#{@errors.join("\n")}"
  end
end

RSpec::Matchers.define :match_schema do |schema, **options|
  match do |data|
    JSON::Validator.validate!(schema_path(schema), data, options)
  end
end
