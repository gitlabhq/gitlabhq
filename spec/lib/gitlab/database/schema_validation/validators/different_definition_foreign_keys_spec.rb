# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::Validators::DifferentDefinitionForeignKeys,
  feature_category: :database do
  include_examples 'foreign key validators', described_class, ['public.wrong_definition_fk']
end
