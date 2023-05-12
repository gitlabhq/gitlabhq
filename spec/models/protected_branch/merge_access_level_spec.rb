# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranch::MergeAccessLevel, feature_category: :source_code_management do
  include_examples 'protected branch access'
  include_examples 'protected ref access allowed_access_levels'
end
