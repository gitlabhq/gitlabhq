# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::GroupDistributionKey do
  it_behaves_like 'Debian Distribution Key', :group
end
