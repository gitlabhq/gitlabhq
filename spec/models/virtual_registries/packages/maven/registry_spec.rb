# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VirtualRegistries::Packages::Maven::Registry, type: :model, feature_category: :virtual_registry do
  subject(:registry) { build(:virtual_registries_packages_maven_registry) }

  describe 'associations' do
    it { is_expected.to belong_to(:group) }

    it do
      is_expected.to have_one(:registry_upstream)
        .class_name('VirtualRegistries::Packages::Maven::RegistryUpstream')
        .inverse_of(:registry)
    end

    it do
      is_expected.to have_one(:upstream)
        .through(:registry_upstream)
        .class_name('VirtualRegistries::Packages::Maven::Upstream')
    end
  end

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:group) }
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_numericality_of(:cache_validity_hours).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe '.for_group' do
    let_it_be(:group) { create(:group) }
    let_it_be(:registry) { create(:virtual_registries_packages_maven_registry, group: group) }
    let_it_be(:other_registry) { create(:virtual_registries_packages_maven_registry) }

    subject { described_class.for_group(group) }

    it { is_expected.to eq([registry]) }
  end
end
