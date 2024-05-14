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
    let_it_be(:partner_catalog_namespace) { create(:catalog_verified_namespace, :gitlab_partner_maintained) }

    it 'sets verification level to partner' do
      expect(partner_catalog_namespace.verification_level).to eq('gitlab_partner_maintained')
    end
  end

  context 'when verified creator namespace is created' do
    let_it_be(:verified_creator_catalog_namespace) { create(:catalog_verified_namespace, :verified_creator_maintained) }

    it 'sets verification level to verified_creator' do
      expect(verified_creator_catalog_namespace.verification_level).to eq('verified_creator_maintained')
    end
  end

  context 'when unverified is created' do
    let_it_be(:verified_creator_catalog_namespace) { create(:catalog_verified_namespace, :unverified) }

    it 'sets verification level to unverified' do
      expect(verified_creator_catalog_namespace).to be_unverified
    end
  end

  it do
    is_expected.to define_enum_for(:verification_level).with_values(
      { gitlab_maintained: 100, gitlab_partner_maintained: 50, verified_creator_maintained: 10, unverified: 0 }
    )
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

  describe '.for_project' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project) { create(:project, group: subgroup) }
    let_it_be(:verified_namespace) { create(:catalog_verified_namespace, namespace: group) }

    it "fetches the verified namespace for the project's root namespace" do
      expect(described_class.for_project(project)).to eq(verified_namespace)
    end
  end
end
