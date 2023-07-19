# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedTag::CreateAccessLevel, feature_category: :source_code_management do
  include_examples 'protected tag access'
  include_examples 'protected ref deploy_key access'
  include_examples 'protected ref access allowed_access_levels'
end
