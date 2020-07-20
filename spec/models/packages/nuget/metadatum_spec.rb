# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::Metadatum, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package).inverse_of(:nuget_metadatum) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }

    %i[license_url project_url icon_url].each do |url|
      describe "##{url}" do
        it { is_expected.to allow_value('http://sandbox.com').for(url) }
        it { is_expected.to allow_value('https://sandbox.com').for(url) }
        it { is_expected.not_to allow_value('123').for(url) }
        it { is_expected.not_to allow_value('sandbox.com').for(url) }
      end

      describe '#ensure_at_least_one_field_supplied' do
        subject { build(:nuget_metadatum) }

        it 'rejects unfilled metadatum' do
          subject.attributes = { license_url: nil, project_url: nil, icon_url: nil }

          expect(subject).not_to be_valid
          expect(subject.errors).to contain_exactly('Nuget metadatum must have at least license_url, project_url or icon_url set')
        end
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
