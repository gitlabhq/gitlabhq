# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EtagCaching::Store, :clean_gitlab_redis_cache do
  let(:store) { described_class.new }

  describe '#get' do
    subject { store.get(key) }

    context 'with invalid keys' do
      let(:key) { 'a' }

      it 'raises errors' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).and_call_original

        expect { subject }.to raise_error Gitlab::EtagCaching::Store::InvalidKeyError
      end

      it 'does not raise errors in production' do
        expect(store).to receive(:skip_validation?).and_return true
        expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

        subject
      end
    end

    context 'with GraphQL keys' do
      let(:key) { '/api/graphql:pipelines/id/5' }

      it 'returns a stored value' do
        etag = store.touch(key)

        is_expected.to eq(etag)
      end
    end

    context 'with RESTful keys' do
      let(:key) { '/my-group/my-project/builds/234.json' }

      it 'returns a stored value' do
        etag = store.touch(key)

        is_expected.to eq(etag)
      end
    end
  end

  describe '#touch' do
    subject { store.touch(key) }

    context 'with invalid keys' do
      let(:key) { 'a' }

      it 'raises errors' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).and_call_original

        expect { subject }.to raise_error Gitlab::EtagCaching::Store::InvalidKeyError
      end
    end

    context 'with GraphQL keys' do
      let(:key) { '/api/graphql:pipelines/id/5' }

      it 'stores and returns a value' do
        etag = store.touch(key)

        expect(etag).to be_present
        expect(store.get(key)).to eq(etag)
      end
    end

    context 'with RESTful keys' do
      let(:key) { '/my-group/my-project/builds/234.json' }

      it 'stores and returns a value' do
        etag = store.touch(key)

        expect(etag).to be_present
        expect(store.get(key)).to eq(etag)
      end
    end

    context 'with multiple keys' do
      let(:keys) { ['/my-group/my-project/builds/234.json', '/api/graphql:pipelines/id/5'] }

      it 'stores and returns multiple values' do
        etags = store.touch(*keys)

        expect(etags.size).to eq(keys.size)

        keys.each_with_index do |key, i|
          expect(store.get(key)).to eq(etags[i])
        end
      end
    end
  end
end
