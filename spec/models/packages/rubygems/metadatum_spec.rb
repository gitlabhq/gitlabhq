# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Rubygems::Metadatum, type: :model, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }
  end
end
