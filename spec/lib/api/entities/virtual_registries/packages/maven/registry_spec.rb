# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::VirtualRegistries::Packages::Maven::Registry, feature_category: :virtual_registry do
  let(:registry) { build_stubbed(:virtual_registries_packages_maven_registry) }

  subject { described_class.new(registry).as_json }

  it { is_expected.to include(:id, :group_id, :created_at, :updated_at) }
end
