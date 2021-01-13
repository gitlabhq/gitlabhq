# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::GroupArchitecture do
  it_behaves_like 'Debian Distribution Architecture', :debian_group_architecture, :group, false
end
