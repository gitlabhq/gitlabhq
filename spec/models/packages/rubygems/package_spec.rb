# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Rubygems::Package, type: :model, feature_category: :package_registry do
  let_it_be(:rubygems_package) { build_stubbed(:rubygems_package) }

  describe 'associations' do
    it { is_expected.to have_one(:rubygems_metadatum).inverse_of(:package).class_name('Packages::Rubygems::Metadatum') }
  end

  describe 'validations' do
    describe '#name' do
      it_behaves_like 'validate package name format', :rubygems_package
    end
  end

  describe '.installable' do
    it_behaves_like 'installable packages', :rubygems_package
  end
end
