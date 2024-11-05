# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::VirtualRegistries::Packages::Maven::Upstream, feature_category: :virtual_registry do
  let(:upstream) { build_stubbed(:virtual_registries_packages_maven_upstream) }

  subject { described_class.new(upstream).as_json }

  it { is_expected.to include(:id, :group_id, :url, :cache_validity_hours, :created_at, :updated_at) }
end
