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
end
