# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::ProjectDistributionKey do
  it_behaves_like 'Debian Distribution Key', :project
end
