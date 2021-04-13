# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::ObjectPoolService do
  let(:pool_repository) { create(:pool_repository) }
  let(:project) { create(:project, :repository) }
  let(:raw_repository) { project.repository.raw }
  let(:object_pool) { pool_repository.object_pool }

  subject { described_class.new(object_pool) }

  before do
    subject.create(raw_repository) # rubocop:disable Rails/SaveBang
  end

  describe '#create' do
    it 'exists on disk' do
      expect(object_pool.repository.exists?).to be(true)
    end

    context 'when the pool already exists' do
      it 'returns an error' do
        expect do
          subject.create(raw_repository) # rubocop:disable Rails/SaveBang
        end.to raise_error(GRPC::FailedPrecondition)
      end
    end
  end

  describe '#delete' do
    it 'removes the repository from disk' do
      subject.delete

      expect(object_pool.repository.exists?).to be(false)
    end

    context 'when called twice' do
      it "doesn't raise an error" do
        subject.delete

        expect { object_pool.delete }.not_to raise_error
      end
    end
  end

  describe '#fetch' do
    before do
      subject.delete
    end

    it 'restores the pool repository objects' do
      subject.fetch(project.repository)

      expect(object_pool.repository.exists?).to be(true)
    end

    context 'when called twice' do
      it "doesn't raise an error" do
        subject.delete

        expect { subject.fetch(project.repository) }.not_to raise_error
      end
    end
  end
end
