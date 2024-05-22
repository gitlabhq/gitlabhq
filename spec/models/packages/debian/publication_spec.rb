# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::Publication, type: :model, feature_category: :package_registry do
  let_it_be_with_reload(:publication) { create(:debian_publication) }

  subject { publication }

  describe 'relationships' do
    it { is_expected.to belong_to(:package).inverse_of(:publication).class_name('Packages::Debian::Package') }
    it { is_expected.to belong_to(:distribution).inverse_of(:publications).class_name('Packages::Debian::ProjectDistribution').with_foreign_key(:distribution_id) }
  end

  describe 'validations' do
    describe '#package' do
      it { is_expected.to validate_presence_of(:package) }
    end

    describe '#distribution' do
      it { is_expected.to validate_presence_of(:distribution) }
    end
  end
end
