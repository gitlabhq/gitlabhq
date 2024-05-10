# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::ProjectComponentFile, feature_category: :package_registry do
  it_behaves_like 'Debian Component File', :project, true
end
