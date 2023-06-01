# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::Metadatum, type: :model, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to belong_to(:package).inverse_of(:nuget_metadatum) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }

    it { is_expected.to validate_presence_of(:authors) }
    it { is_expected.to validate_length_of(:authors).is_at_most(described_class::MAX_AUTHORS_LENGTH) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(described_class::MAX_DESCRIPTION_LENGTH) }

    %i[license_url project_url icon_url].each do |url|
      describe "##{url}" do
        it { is_expected.to allow_value('http://sandbox.com').for(url) }
        it { is_expected.to allow_value('https://sandbox.com').for(url) }
        it { is_expected.not_to allow_value('123').for(url) }
        it { is_expected.not_to allow_value('sandbox.com').for(url) }
      end

      describe '#ensure_nuget_package_type' do
        subject { build(:nuget_metadatum) }

        it 'rejects if not linked to a nuget package' do
          subject.package = build(:npm_package)

          expect(subject).not_to be_valid
          expect(subject.errors).to contain_exactly('Package type must be NuGet')
        end
      end
    end
  end
end
