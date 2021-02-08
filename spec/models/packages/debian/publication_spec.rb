# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Debian::Publication, type: :model do
  let_it_be_with_reload(:publication) { create(:debian_publication) }

  subject { publication }

  describe 'relationships' do
    it { is_expected.to belong_to(:package).inverse_of(:debian_publication).class_name('Packages::Package') }
    it { is_expected.to belong_to(:distribution).inverse_of(:publications).class_name('Packages::Debian::ProjectDistribution').with_foreign_key(:distribution_id) }
  end

  describe 'validations' do
    describe '#package' do
      it { is_expected.to validate_presence_of(:package) }
    end

    describe '#valid_debian_package_type' do
      context 'with package type not being Debian' do
        before do
          publication.package.package_type = 'generic'
        end

        it 'will not allow package type not being Debian' do
          expect(publication).not_to be_valid
          expect(publication.errors.to_a).to eq(['Package type must be Debian'])
        end
      end

      context 'with package not being a Debian package' do
        before do
          publication.package.version = nil
        end

        it 'will not allow package not being a distribution' do
          expect(publication).not_to be_valid
          expect(publication.errors.to_a).to eq(['Package must be a Debian package'])
        end
      end
    end

    describe '#distribution' do
      it { is_expected.to validate_presence_of(:distribution) }
    end
  end
end
