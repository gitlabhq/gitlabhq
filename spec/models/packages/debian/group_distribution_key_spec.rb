# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::GroupDistributionKey, feature_category: :package_registry do
  it_behaves_like 'Debian Distribution Key', :group
end
