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
    unless @schema_cache.key?(schema_path)
      @schema_cache[schema_path] = JSONSchemer.schema(schema_path, ref_resolver: SchemaPath.file_ref_resolver)
    end

    @schema_cache[schema_path]
  end

  def self.file_ref_resolver
    proc do |uri|
      file = Rails.root.join(uri.path)
      raise StandardError, "Ref file #{uri.path} must be json" unless uri.path.ends_with?('.json')
      raise StandardError, "File #{file.to_path} doesn't exists" unless file.exist?

      Gitlab::Json.parse(File.read(file))
    end
  end
end

RSpec::Matchers.define :match_response_schema do |schema, dir: nil, **options|
  match do |response|
    schema_path = Pathname.new(SchemaPath.expand(schema, dir))
    validator = SchemaPath.validator(schema_path)

    data = Gitlab::Json.parse(response.body)

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

RSpec::Matchers.define :match_schema do |schema, dir: nil, **options|
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
