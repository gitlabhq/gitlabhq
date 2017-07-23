def schema_path(schema)
  schema_directory = "#{Dir.pwd}/spec/fixtures/api/schemas"
  "#{schema_directory}/#{schema}.json"
end

RSpec::Matchers.define :match_response_schema do |schema, **options|
  match do |response|
    JSON::Validator.validate!(schema_path(schema), response.body, options)
  end
end

RSpec::Matchers.define :match_schema do |schema, **options|
  match do |data|
    JSON::Validator.validate!(schema_path(schema), data, options)
  end
end
