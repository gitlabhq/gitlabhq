# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::ProjectComponent do
  it_behaves_like 'Debian Distribution Component', :debian_project_component, :project, true
end
