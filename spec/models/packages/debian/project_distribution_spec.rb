# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::ProjectDistribution do
  it_behaves_like 'Debian Distribution', :debian_project_distribution, :project, true
end
