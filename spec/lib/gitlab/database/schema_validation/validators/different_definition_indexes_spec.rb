# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::Validators::DifferentDefinitionIndexes,
  feature_category: :database do
  include_examples 'index validators', described_class, ['wrong_index']
end
