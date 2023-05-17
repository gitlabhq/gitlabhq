# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectPool::JoinWorker, feature_category: :shared do
  let(:pool) { create(:pool_repository, :ready) }
  let(:project) { pool.source_project }
  let(:repository) { project.repository }

  subject { described_class.new }

  describe '#perform' do
    context "when the pool is not joinable" do
      let(:pool) { create(:pool_repository, :scheduled) }

      it "doesn't raise an error" do
        expect do
          subject.perform(pool.id, project.id)
        end.not_to raise_error
      end
    end

    context 'when the pool has been joined before' do
      before do
        pool.link_repository(repository)
      end

      it 'succeeds in joining' do
        expect do
          subject.perform(pool.id, project.id)
        end.not_to raise_error
      end
    end
  end
end
