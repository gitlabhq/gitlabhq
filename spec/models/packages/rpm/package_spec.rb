# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Rpm::Package, type: :model, feature_category: :package_registry do
  describe 'associations' do
    it { is_expected.to have_one(:rpm_metadatum).inverse_of(:package).class_name('Packages::Rpm::Metadatum') }
  end

  describe '.installable' do
    it_behaves_like 'installable packages', :rpm_package
  end
end
