module SchemaPath
  def self.expand(schema, dir = '')
    Rails.root.join('spec', dir, "fixtures/api/schemas/#{schema}.json").to_s
  end
end

RSpec::Matchers.define :match_response_schema do |schema, dir: '', **options|
  match do |response|
    @errors = JSON::Validator.fully_validate(
      SchemaPath.expand(schema, dir), response.body, options)

    @errors.empty?
  end

  failure_message do |response|
    "didn't match the schema defined by #{SchemaPath.expand(schema, dir)}" \
    " The validation errors were:\n#{@errors.join("\n")}"
  end
end

RSpec::Matchers.define :match_schema do |schema, dir: '', **options|
  match do |data|
    JSON::Validator.validate!(SchemaPath.expand(schema, dir), data, options)
  end
end
