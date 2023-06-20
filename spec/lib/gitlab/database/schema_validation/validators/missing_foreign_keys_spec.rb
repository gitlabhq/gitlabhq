# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::Validators::MissingForeignKeys, feature_category: :database do
  include_examples 'foreign key validators', described_class, %w[public.fk_rails_536b96bff1 public.missing_fk]
end
