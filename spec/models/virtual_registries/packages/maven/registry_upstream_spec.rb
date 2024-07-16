# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VirtualRegistries::Packages::Maven::RegistryUpstream, type: :model, feature_category: :virtual_registry do
  subject(:registry_upstream) { build(:virtual_registries_packages_maven_registry_upstream) }

  describe 'associations' do
    it { is_expected.to belong_to(:group) }

    it do
      is_expected.to belong_to(:registry)
        .class_name('VirtualRegistries::Packages::Maven::Registry')
        .inverse_of(:registry_upstream)
    end

    it do
      is_expected.to belong_to(:upstream)
       .class_name('VirtualRegistries::Packages::Maven::Upstream')
      .inverse_of(:registry_upstream)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_uniqueness_of(:registry_id) }
    it { is_expected.to validate_uniqueness_of(:upstream_id) }
  end
end
