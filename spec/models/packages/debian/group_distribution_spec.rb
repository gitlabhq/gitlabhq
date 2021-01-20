# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::GroupDistribution do
  it_behaves_like 'Debian Distribution', :debian_group_distribution, :group, false
end
