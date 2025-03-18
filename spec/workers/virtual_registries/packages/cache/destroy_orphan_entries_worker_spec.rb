# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VirtualRegistries::Packages::Cache::DestroyOrphanEntriesWorker, type: :worker, feature_category: :virtual_registry do
  let(:worker) { described_class.new }
  let(:model) { ::VirtualRegistries::Packages::Maven::Cache::Entry }

  describe '#perform_work', unless: Gitlab.ee? do
    subject(:perform_work) { worker.perform_work(model.name) }

    let_it_be(:cache_entry) { create(:virtual_registries_packages_maven_cache_entry) }
    let_it_be(:orphan_cache_entry) do
      create(:virtual_registries_packages_maven_cache_entry, :pending_destruction)
    end

    it { expect { perform_work }.to not_change { model.count } }
  end

  describe '#remaining_work_count', unless: Gitlab.ee? do
    subject { worker.remaining_work_count(model.name) }

    it { is_expected.to eq(0) }
  end
end
