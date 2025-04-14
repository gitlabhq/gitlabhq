# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VirtualRegistries::Packages::Cache::DestroyOrphanEntriesWorker, type: :worker, feature_category: :virtual_registry do
  let(:worker) { described_class.new }

  describe '#perform_work', unless: Gitlab.ee? do
    subject(:perform_work) { worker.perform_work('') }

    it 'does not trigger any sql query' do
      control = ActiveRecord::QueryRecorder.new { perform_work }
      expect(control.count).to be_zero
    end
  end

  describe '#remaining_work_count', unless: Gitlab.ee? do
    subject { worker.remaining_work_count('') }

    it { is_expected.to be_zero }
  end
end
