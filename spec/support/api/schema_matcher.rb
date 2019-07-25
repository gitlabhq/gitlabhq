# frozen_string_literal: true

module SchemaPath
  def self.expand(schema, dir = nil)
    if Gitlab.ee? && dir.nil?
      ee_path = expand(schema, 'ee')

      return ee_path if File.exist?(ee_path)
    end

    Rails.root.join(dir.to_s, 'spec', "fixtures/api/schemas/#{schema}.json").to_s
  end
end

RSpec::Matchers.define :match_response_schema do |schema, dir: nil, **options|
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

RSpec::Matchers.define :match_schema do |schema, dir: nil, **options|
  match do |data|
    @errors = JSON::Validator.fully_validate(
      SchemaPath.expand(schema, dir), data, options)

    @errors.empty?
  end

  failure_message do |response|
    "didn't match the schema defined by #{SchemaPath.expand(schema, dir)}" \
    " The validation errors were:\n#{@errors.join("\n")}"
  end
end
