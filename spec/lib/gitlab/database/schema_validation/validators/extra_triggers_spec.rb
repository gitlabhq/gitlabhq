# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::Validators::ExtraTriggers, feature_category: :database do
  include_examples 'trigger validators', described_class, ['extra_trigger']
end
