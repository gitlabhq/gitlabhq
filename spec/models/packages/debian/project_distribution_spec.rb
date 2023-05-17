# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::ProjectDistribution, feature_category: :package_registry do
  include_context 'for Debian Distribution', :debian_project_distribution, true

  it_behaves_like 'Debian Distribution for common behavior'
  it_behaves_like 'Debian Distribution with project container'
end
