# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::PackageFileBuildInfo, type: :model, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to belong_to(:package_file) }
    it { is_expected.to belong_to(:pipeline) }
  end

  describe '#pipeline' do
    it_behaves_like 'a partition-pruned pipeline association' do
      let(:related_resource) { create(:package_file_build_info, pipeline_id: pipeline.id) }
    end
  end
end
