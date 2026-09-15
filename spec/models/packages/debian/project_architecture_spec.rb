# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::ProjectArchitecture, feature_category: :package_registry do
  it_behaves_like 'Debian Distribution Architecture', :debian_project_architecture, :project, true
end
