# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::Metadatum, type: :model, feature_category: :package_registry do
  it { is_expected.to be_a Packages::Nuget::VersionNormalizable }

  describe 'relationships' do
    it { is_expected.to belong_to(:package).class_name('Packages::Nuget::Package').inverse_of(:nuget_metadatum) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:authors) }
    it { is_expected.to validate_length_of(:authors).is_at_most(described_class::MAX_AUTHORS_LENGTH) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(described_class::MAX_DESCRIPTION_LENGTH) }
    it { is_expected.to validate_presence_of(:normalized_version) }

    %i[license_url project_url icon_url].each do |url|
      describe "##{url}" do
        it { is_expected.to allow_value('http://sandbox.com').for(url) }
        it { is_expected.to allow_value('https://sandbox.com').for(url) }
        it { is_expected.not_to allow_value('123').for(url) }
        it { is_expected.not_to allow_value('sandbox.com').for(url) }
        it { is_expected.to validate_length_of(url).is_at_most(described_class::MAX_URL_LENGTH) }
      end

      describe "skip #{url} validation" do
        before do
          stub_application_setting(nuget_skip_metadata_url_validation: true)
        end

        it { is_expected.not_to allow_value('123').for(url) }
        it { is_expected.not_to allow_value('sandbox.com').for(url) }
      end

      describe '#ensure_nuget_package_type', :aggregate_failures do
        subject(:nuget_metadatum) { build(:nuget_metadatum) }

        it 'builds a valid metadatum' do
          expect { nuget_metadatum }.not_to raise_error
          expect(nuget_metadatum).to be_valid
        end

        context 'with a different package type' do
          let(:package) { build(:generic_package) }

          it 'raises the error' do
            expect { build(:nuget_metadatum, package: package) }.to raise_error(ActiveRecord::AssociationTypeMismatch)
          end
        end
      end
    end
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:version).to(:package).with_prefix }
  end

  describe '.normalized_version_in' do
    let_it_be(:nuget_metadatums) { create_list(:nuget_metadatum, 2) }

    subject { described_class.normalized_version_in(nuget_metadatums.first.normalized_version) }

    it { is_expected.to contain_exactly(nuget_metadatums.first) }
  end

  describe 'callbacks' do
    describe '#set_normalized_version' do
      using RSpec::Parameterized::TableSyntax

      let_it_be_with_reload(:nuget_metadatum) { create(:nuget_metadatum) }

      where(:version, :normalized_version) do
        '1.0'                     | '1.0.0'
        '1.0.0.0'                 | '1.0.0'
        '0.1'                     | '0.1.0'
        '1.0.7+r3456'             | '1.0.7'
        '8.0.0.00+RC.54'          | '8.0.0'
        '1.0.0-Alpha'             | '1.0.0-alpha'
        '1.0.00-RC-02'            | '1.0.0-rc-02'
        '8.0.000-preview.0.546.0' | '8.0.0-preview.0.546.0'
        '0.1.0-dev.37+0999370'    | '0.1.0-dev.37'
        '1.2.3'                   | '1.2.3'
      end

      with_them do
        it 'saves the normalized version' do
          nuget_metadatum.package.update_column(:version, version)
          nuget_metadatum.save!

          expect(nuget_metadatum.normalized_version).to eq(normalized_version)
        end
      end
    end
  end
end
