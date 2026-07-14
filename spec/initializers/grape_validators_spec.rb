# frozen_string_literal: true

require 'spec_helper'

# Guards config/initializers/grape_validators.rb. That initializer loads every
# custom validator class so Grape's `inherited` hook registers it. In
# development and test the app does not eager-load, so a validator missing from
# the initializer would only surface at runtime as
# Grape::Exceptions::UnknownValidator. This spec reads the validator source
# files directly (rather than loading the classes) so that a file absent from
# the initializer is detected.
RSpec.describe 'config/initializers/grape_validators.rb', feature_category: :api do
  it 'registers every custom validator defined under lib/api/validations/validators',
    :aggregate_failures do
    validator_dir = Rails.root.join('lib/api/validations/validators')

    # [child, parent] pairs for every class declared in the directory.
    declarations = Dir[validator_dir.join('**/*.rb')].flat_map do |file|
      File.read(file).scan(/^\s*class (\w+)\s*<\s*([\w:]+)/)
    end

    # A class is a custom validator only if it inherits from Grape's validator
    # base, either directly or transitively through another validator defined in
    # this directory (e.g. IntegerNoneAny < IntegerOrCustomValue < Base). This
    # ignores any non-validator class that might live alongside them.
    validator_names = declarations.select { |_, parent| parent.end_with?('Validators::Base') }.map(&:first)
    loop do
      transitive = declarations.select do |child, parent|
        validator_names.include?(parent.split('::').last) && validator_names.exclude?(child)
      end.map(&:first)
      break if transitive.empty?

      validator_names.concat(transitive)
    end

    expected_short_names = validator_names.map(&:underscore)

    # Resolve each name through Grape's public lookup, which raises
    # UnknownValidator when a validator is not registered. This works across
    # Grape versions, whereas the internal store moved from `.validators`
    # (Grape 2.0) to a private `registry` (Grape 2.4+).
    unregistered = expected_short_names.reject do |short_name|
      Grape::Validations.require_validator(short_name)
    rescue Grape::Exceptions::UnknownValidator
      false
    end

    expect(expected_short_names).not_to be_empty
    expect(unregistered).to be_empty, "Unregistered validators: #{unregistered.join(', ')}"
  end
end
