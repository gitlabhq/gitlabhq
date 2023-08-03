# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Nuget::Metadatum, feature_category: :package_registry do
  let(:metadatum) do
    {
      authors: 'Authors',
      description: 'Description',
      project_url: 'http://sandbox.com/project',
      license_url: 'http://sandbox.com/license',
      icon_url: 'http://sandbox.com/icon'
    }
  end

  let(:expected) do
    {
      'authors': 'Authors',
      'description': 'Description',
      'summary': 'Description',
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
      let(:metadatum) { super().merge(optional_field => nil) }

      it { is_expected.not_to have_key(optional_field.to_s.camelize(:lower).to_sym) }
    end
  end

  describe 'authors' do
    context 'with default value' do
      let(:metadatum) { super().merge(authors: nil) }

      it { is_expected.to have_key(:authors) }
      it { is_expected.to eq(expected.merge(authors: '')) }
    end
  end

  describe 'description' do
    context 'with default value' do
      let(:metadatum) { super().merge(description: nil) }

      it { is_expected.to have_key(:description) }
      it { is_expected.to have_key(:summary) }

      it { is_expected.to eq(expected.merge(description: '', summary: '')) }
    end
  end
end
