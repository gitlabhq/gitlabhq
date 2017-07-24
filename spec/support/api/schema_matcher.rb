module SchemaPath
  def self.expand(schema, dir = '')
    Rails.root.join('spec', dir, "fixtures/api/schemas/#{schema}.json").to_s
  end
end

RSpec::Matchers.define :match_response_schema do |schema, dir: '', **options|
  match do |response|
    JSON::Validator.validate!(SchemaPath.expand(schema, dir), response.body, options)
  end
end

RSpec::Matchers.define :match_schema do |schema, dir: '', **options|
  match do |data|
    JSON::Validator.validate!(SchemaPath.expand(schema, dir), data, options)
  end
end
