# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::ObjectPoolService, feature_category: :source_code_management do
  let(:pool_repository) { create(:pool_repository) }
  let(:project) { pool_repository.source_project }
  let(:raw_repository) { project.repository.raw }
  let(:object_pool) { pool_repository.object_pool }

  subject { described_class.new(object_pool) }

  before do
    subject.create(raw_repository) # rubocop:disable Rails/SaveBang -- This is a gitaly call
    ::Gitlab::GitalyClient.clear_stubs!
  end

  describe '#create' do
    it 'sends a create_object_pool message' do
      expected_request = Gitaly::CreateObjectPoolRequest.new(
        object_pool: object_pool.gitaly_object_pool,
        origin: raw_repository.gitaly_repository)

      expect_next_instance_of(Gitaly::ObjectPoolService::Stub) do |stub|
        expect(stub)
          .to receive(:create_object_pool)
          .with(expected_request, kind_of(Hash))
      end

      subject.create(raw_repository) # rubocop:disable Rails/SaveBang -- This is a gitaly call
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
