# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::SPDX, feature_category: :dependency_management do
  let_it_be(:license_list) { Gitlab::Json.parse(Rails.root.join('vendor/spdx.json').read) }
  let_it_be(:active_licenses) { license_list['licenses'].reject { |license| license['isDeprecatedLicenseId'] } }
  let_it_be(:active_license_ids) { active_licenses.pluck('licenseId') }

  describe '.licenses' do
    subject(:licenses) { described_class.licenses }

    it 'returns all active licenses converted to POROs' do
      expected = active_licenses.map do |license|
        an_object_having_attributes(
          id: license['licenseId'],
          name: license['name'],
          deprecated: license['isDeprecatedLicenseId']
        )
      end

      expect(licenses).to match_array(expected)
    end
  end

  describe '.identifiers' do
    subject(:identifiers) { described_class.identifiers }

    it 'returns all identifiers from the license list' do
      expect(identifiers).to match_array(active_license_ids)
    end
  end

  describe '.valid_identifier?' do
    it 'returns true when id is valid' do
      active_license_ids.each do |id|
        expect(described_class.valid_identifier?(id)).to be(true)
      end
    end

    context 'when id is deprecated' do
      let_it_be(:deprecated_license_ids) do
        license_list['licenses'].select do |license|
          license['isDeprecatedLicenseId']
        end.pluck('licenseId')
      end

      it 'returns false' do
        deprecated_license_ids.each do |id|
          expect(described_class.valid_identifier?(id)).to be(false)
        end
      end
    end
  end
end
