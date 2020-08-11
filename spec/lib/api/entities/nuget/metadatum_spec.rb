# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Nuget::Metadatum do
  let(:metadatum) do
    {
      project_url: 'http://sandbox.com/project',
      license_url: 'http://sandbox.com/license',
      icon_url: 'http://sandbox.com/icon'
    }
  end

  let(:expected) do
    {
      'projectUrl': 'http://sandbox.com/project',
      'licenseUrl': 'http://sandbox.com/license',
      'iconUrl': 'http://sandbox.com/icon'
    }
  end

  let(:entity) { described_class.new(metadatum) }

  subject { entity.as_json }

  it { is_expected.to eq(expected) }

  %i[project_url license_url icon_url].each do |optional_field|
    context "metadatum without #{optional_field}" do
      let(:metadatum_without_a_field) { metadatum.except(optional_field) }
      let(:expected_without_a_field) { expected.except(optional_field.to_s.camelize(:lower).to_sym) }
      let(:entity) { described_class.new(metadatum_without_a_field) }

      it { is_expected.to eq(expected_without_a_field) }
    end
  end
end
