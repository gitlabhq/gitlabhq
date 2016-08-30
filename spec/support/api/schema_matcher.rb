RSpec::Matchers.define :match_response_schema do |schema, **options|
  match do |response|
    schema_directory = "#{Dir.pwd}/spec/fixtures/api/schemas"
    schema_path = "#{schema_directory}/#{schema}.json"

    JSON::Validator.validate!(schema_path, response.body, options)
  end
end
