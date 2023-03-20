# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Composer::CacheCleanupWorker, type: :worker, feature_category: :package_registry do
  describe '#perform' do
    let_it_be(:group) { create(:group) }

    let!(:cache_file1) { create(:composer_cache_file, delete_at: nil, group: group, file_sha256: '124') }
    let!(:cache_file2) { create(:composer_cache_file, delete_at: 2.days.from_now, group: group, file_sha256: '3456') }
    let!(:cache_file3) { create(:composer_cache_file, delete_at: 1.day.ago, group: group, file_sha256: '5346') }
    let!(:cache_file4) { create(:composer_cache_file, delete_at: nil, group: group, file_sha256: '56889') }

    subject { described_class.new.perform }

    before do
      # emulate group deletion
      cache_file4.update_columns(namespace_id: nil)
    end

    it 'does nothing' do
      expect { subject }.not_to change { Packages::Composer::CacheFile.count }
    end
  end
end
