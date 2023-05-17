# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::GroupDistribution, feature_category: :package_registry do
  include_context 'for Debian Distribution', :debian_group_distribution, false

  it_behaves_like 'Debian Distribution for common behavior'
  it_behaves_like 'Debian Distribution with group container'
end
