# frozen_string_literal: true

module SchemaPath
  @schema_cache = {}

  def self.expand(schema, dir = nil)
    return schema unless schema.is_a?(String)

    if Gitlab.ee? && dir.nil?
      ee_path = expand(schema, 'ee')

      return ee_path if File.exist?(ee_path)
    end

    Rails.root.join(dir.to_s, 'spec', "fixtures/api/schemas/#{schema}.json").to_s
  end

  def self.validator(schema_path)
    @schema_cache.fetch(schema_path) do
      @schema_cache[schema_path] = JSONSchemer.schema(schema_path)
    end
  end
end

RSpec::Matchers.define :match_response_schema do |schema, dir: nil, **options|
  match do |response|
    @schema_path = Pathname.new(SchemaPath.expand(schema, dir))
    validator = SchemaPath.validator(@schema_path)

    @data = Gitlab::Json.parse(response.body)

    @schema_errors = validator.validate(@data)
    @schema_errors.none?
  end

  failure_message do |actual|
    message = []

    message << <<~MESSAGE
      expected JSON response to match schema #{@schema_path.inspect}.

      JSON input: #{Gitlab::Json.pretty_generate(@data).indent(2)}

      Schema errors:
    MESSAGE

    @schema_errors.each do |error|
      property_name, actual_value = error.values_at('data_pointer', 'data')
      property_name = 'root' if property_name.empty?

      message << <<~MESSAGE
        Property: #{property_name}
          Actual value: #{Gitlab::Json.pretty_generate(actual_value).indent(2)}
          Error: #{JSONSchemer::Errors.pretty(error)}
      MESSAGE
    end

    message.join("\n")
  end
end

RSpec::Matchers.define :match_metric_definition_schema do |path, dir: nil, **options|
  match do |data|
    schema_path = Pathname.new(Rails.root.join(dir.to_s, path).to_s)
    validator = SchemaPath.validator(schema_path)

    data = data.stringify_keys if data.is_a? Hash

    validator.valid?(data)
  end
end

RSpec::Matchers.define :match_snowplow_schema do |schema, dir: nil, **options|
  match do |data|
    schema_path = Pathname.new(Rails.root.join(dir.to_s, 'spec', "fixtures/product_intelligence/#{schema}.json").to_s)
    validator = SchemaPath.validator(schema_path)

    validator.valid?(data.stringify_keys)
  end
end

RSpec::Matchers.define :match_schema do |schema, options = {}|
  # NOTE: https://github.com/rspec/rspec-support/pull/591 broke kwarg parsing
  dir = options.fetch(:dir, nil)

  match do |data|
    schema = SchemaPath.expand(schema, dir)
    schema = Pathname.new(schema) if schema.is_a?(String)
    validator = SchemaPath.validator(schema)

    if data.is_a?(String)
      validator.valid?(Gitlab::Json.parse(data))
    else
      validator.valid?(data)
    end
  end
end
