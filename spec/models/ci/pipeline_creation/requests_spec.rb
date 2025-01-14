# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineCreation::Requests, :clean_gitlab_redis_shared_state, feature_category: :pipeline_composition do
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:project) { merge_request.project }

  describe '.failed' do
    context 'when given a pipeline creation key and ID' do
      it 'sets the pipeline creation to the failed status' do
        request = described_class.start_for_merge_request(merge_request)

        described_class.failed(request, 'Insufficient permissions')

        expect(described_class.hget(request)).to eq(
          { 'status' => 'failed', 'error' => 'Insufficient permissions' }
        )
      end
    end

    context 'when not given a request' do
      it 'returns nil' do
        expect(described_class.failed(nil, 'Insufficient permissions')).to be_nil
      end
    end
  end

  describe '.succeeded' do
    context 'when given a pipeline creation key and ID' do
      it 'sets the pipeline creation to the succeeded status' do
        request = described_class.start_for_merge_request(merge_request)

        described_class.succeeded(request, 1)

        expect(described_class.hget(request)).to eq(
          { 'status' => 'succeeded', 'pipeline_id' => 1 }
        )
      end
    end

    context 'when not given a request' do
      it 'returns nil' do
        expect(described_class.succeeded(nil, 1)).to be_nil
      end
    end
  end

  describe '.start_for_project' do
    it 'stores a pipeline creation for the project and returns its key and ID' do
      allow(SecureRandom).to receive(:uuid).and_return('test-id')

      request = described_class.start_for_project(project)

      expect(request).to eq({
        'key' => described_class.request_key(project, 'test-id'),
        'id' => 'test-id'
      })
      expect(described_class.hget(request)).to eq({ 'status' => 'in_progress' })
    end
  end

  describe '.start_for_merge_request' do
    it 'stores a pipeline creation for the merge request and returns its key and ID' do
      allow(SecureRandom).to receive(:uuid).and_return('test-id')

      request = described_class.start_for_merge_request(merge_request)

      allow(SecureRandom).to receive(:uuid).and_return('test-id-2')

      request2 = described_class.start_for_merge_request(merge_request)

      described_class.succeeded(request, 1)

      expect(request).to eq({
        'key' => described_class.merge_request_key(merge_request),
        'id' => 'test-id'
      })

      expect(described_class.hget(request)).to eq({ 'status' => 'succeeded', 'pipeline_id' => 1 })
      expect(described_class.hget(request2)).to eq({ 'status' => 'in_progress' })
    end
  end

  describe '.pipeline_creating_for_merge_request?' do
    context 'when there are pipeline creations for the merge request' do
      it 'returns true' do
        described_class.start_for_merge_request(merge_request)

        expect(described_class.pipeline_creating_for_merge_request?(merge_request)).to be_truthy
      end
    end

    context 'when there are no pipeline creations for the merge request' do
      it 'returns false' do
        expect(described_class.pipeline_creating_for_merge_request?(merge_request)).to be_falsey
      end
    end
  end

  describe '.get_request' do
    it 'returns the data for the request' do
      request = described_class.start_for_project(project)

      expect(described_class.get_request(project, request['id'])).to eq(
        { 'status' => described_class::IN_PROGRESS }
      )
    end
  end

  describe '.hset' do
    it 'writes the pipeline creation to the Redis cache' do
      request = { 'key' => 'test_key', 'id' => 'test_id' }
      described_class.hset(request, 'status')

      expect(described_class.hget(request)).to eq({ 'status' => 'status' })
    end

    it 'expires the cache after 5 minutes' do
      multi = instance_double(Redis::MultiConnection, hset: nil)

      Gitlab::Redis::SharedState.with do |redis|
        allow(redis).to receive(:multi).and_yield(multi)

        expect(multi).to receive(:expire).with('test_key', described_class::REDIS_EXPIRATION_TIME)

        request = { 'key' => 'test_key', 'id' => 'test_id' }
        described_class.hset(request, 'status')
      end
    end
  end

  describe '.hget' do
    it 'returns the data for the request' do
      request = described_class.start_for_merge_request(merge_request)

      expect(described_class.hget(request)).to eq(
        { 'status' => described_class::IN_PROGRESS }
      )
    end
  end

  describe '.request_key' do
    it 'returns the Redis cache key for a single pipeline creation request' do
      request_id = described_class.generate_id

      expect(described_class.request_key(project, request_id)).to eq(
        "pipeline_creation:projects:{#{project.id}}:request:{#{request_id}}"
      )
    end
  end

  describe '.merge_request_key' do
    it 'returns the Redis cache key for the project' do
      expect(described_class.merge_request_key(merge_request)).to eq(
        "pipeline_creation:projects:{#{merge_request.project.id}}:mrs:{#{merge_request.id}}"
      )
    end
  end

  describe '.generate_id' do
    it 'creates a unique ID for the pipeline creation' do
      expect(SecureRandom).to receive(:uuid)

      described_class.generate_id
    end
  end
end
