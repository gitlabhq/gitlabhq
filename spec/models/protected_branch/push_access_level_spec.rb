# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranch::PushAccessLevel, feature_category: :source_code_management do
  it_behaves_like 'protected branch access'
  it_behaves_like 'protected ref deploy_key access'
  it_behaves_like 'protected ref access allowed_access_levels'
end
