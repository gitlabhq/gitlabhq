# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SshKeys::UpdateLastUsedAtWorker, type: :worker, feature_category: :source_code_management do
  let_it_be(:key) { create(:key) }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [key.id] }
  end

  describe '#perform' do
    subject(:worker) { described_class.new }

    it 'updates last_used_at column', :freeze_time do
      expect { worker.perform(key.id) }.to change { key.reload.last_used_at }.to(Time.zone.now)
    end

    it 'does not update updated_at column' do
      expect { worker.perform(key.id) }.not_to change { key.reload.updated_at }
    end
  end
end
