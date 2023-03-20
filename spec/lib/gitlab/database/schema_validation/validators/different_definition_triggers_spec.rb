# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::Validators::DifferentDefinitionTriggers,
  feature_category: :database do
  include_examples 'trigger validators', described_class, ['wrong_trigger']
end
