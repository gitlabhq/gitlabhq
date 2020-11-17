# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::PackageFileBuildInfo, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package_file) }
    it { is_expected.to belong_to(:pipeline) }
  end
end
