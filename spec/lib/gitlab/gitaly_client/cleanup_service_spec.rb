# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GitalyClient::CleanupService do
  let(:project) { create(:project) }
  let(:storage_name) { project.repository_storage }
  let(:relative_path) { project.disk_path + '.git' }
  let(:client) { described_class.new(project.repository) }

  describe '#apply_bfg_object_map_stream' do
    before do
      ::Gitlab::GitalyClient.clear_stubs!
    end

    it 'sends an apply_bfg_object_map_stream message' do
      expect_next_instance_of(Gitaly::CleanupService::Stub) do |instance|
        expect(instance).to receive(:apply_bfg_object_map_stream)
          .with(kind_of(Enumerator), kind_of(Hash))
          .and_return([])
      end

      client.apply_bfg_object_map_stream(StringIO.new)
    end
  end
end
