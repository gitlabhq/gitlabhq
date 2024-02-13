# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::VerifiedNamespace, feature_category: :pipeline_composition do
  context 'when gitlab maintained namespace is created' do
    let_it_be(:gitlab_catalog_namespace) { create(:catalog_verified_namespace, :gitlab_maintained) }

    it 'sets verification level to gitlab maintained' do
      expect(gitlab_catalog_namespace.verification_level).to eq('gitlab_maintained')
    end
  end

  context 'when partner namespace is created' do
    let_it_be(:partner_catalog_namespace) { create(:catalog_verified_namespace, :partner) }

    it 'sets verification level to partner' do
      expect(partner_catalog_namespace.verification_level).to eq('partner')
    end
  end

  context 'when verfied creator namespace is created' do
    let_it_be(:verified_creator_catalog_namespace) { create(:catalog_verified_namespace, :verified_creator) }

    it 'sets verification level to verified_creator' do
      expect(verified_creator_catalog_namespace.verification_level).to eq('verified_creator')
    end
  end

  it do
    is_expected.to define_enum_for(:verification_level)
      .with_values({ gitlab_maintained: 100, partner: 50, verified_creator: 10, unverified: 0 })
  end

  describe 'validations' do
    let(:verified_namespace) { subject }

    it { is_expected.to validate_presence_of(:namespace_id) }
    it { is_expected.to belong_to(:namespace) }

    it do
      verified_namespace.namespace_id = create(:namespace).id
      is_expected.to validate_uniqueness_of(:namespace_id)
    end
  end
end
