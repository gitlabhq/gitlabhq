# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::ObjectPoolService do
  let(:pool_repository) { create(:pool_repository) }
  let(:project) { pool_repository.source_project }
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
    context 'without changes' do
      it 'fetches changes' do
        expect(subject.fetch(project.repository)).to eq(Gitaly::FetchIntoObjectPoolResponse.new)
      end
    end

    context 'with new reference in source repository' do
      let(:branch) { 'ref-to-be-fetched' }
      let(:source_ref) { "refs/heads/#{branch}" }
      let(:pool_ref) { "refs/remotes/origin/heads/#{branch}" }

      before do
        # Create a new reference in the source repository that we can fetch.
        project.repository.write_ref(source_ref, 'refs/heads/master')
      end

      it 'fetches changes' do
        # Sanity-check to verify that the reference only exists in the source repository now, but not in the
        # object pool.
        expect(project.repository.ref_exists?(source_ref)).to be(true)
        expect(object_pool.repository.ref_exists?(pool_ref)).to be(false)

        subject.fetch(project.repository)

        # The fetch should've created the reference in the object pool.
        expect(object_pool.repository.ref_exists?(pool_ref)).to be(true)
      end
    end
  end
end
