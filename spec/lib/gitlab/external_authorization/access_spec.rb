# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ExternalAuthorization::Access, :clean_gitlab_redis_cache do
  subject(:access) { described_class.new(build(:user), 'dummy_label') }

  describe '#loaded?' do
    it 'is `true` when it was loaded recently' do
      Timecop.freeze do
        allow(access).to receive(:loaded_at).and_return(5.minutes.ago)

        expect(access).to be_loaded
      end
    end

    it 'is `false` when there is no loading time' do
      expect(access).not_to be_loaded
    end

    it 'is `false` when there the result was loaded a long time ago' do
      Timecop.freeze do
        allow(access).to receive(:loaded_at).and_return(2.weeks.ago)

        expect(access).not_to be_loaded
      end
    end
  end

  describe 'load!' do
    let(:fake_client) { double('ExternalAuthorization::Client') }
    let(:fake_response) do
      double(
        'Response',
        'successful?' => true,
        'valid?' => true,
        'reason' => nil
      )
    end

    before do
      allow(access).to receive(:load_from_cache)
      allow(fake_client).to receive(:request_access).and_return(fake_response)
      allow(Gitlab::ExternalAuthorization::Client).to receive(:new) { fake_client }
    end

    context 'when loading from the webservice' do
      it 'loads from the webservice it the cache was empty' do
        expect(access).to receive(:load_from_cache)
        expect(access).to receive(:load_from_service).and_call_original

        access.load!

        expect(access).to be_loaded
      end

      it 'assigns the accessibility, reason and loaded_at' do
        allow(fake_response).to receive(:successful?).and_return(false)
        allow(fake_response).to receive(:reason).and_return('Inaccessible label')

        access.load!

        expect(access.reason).to eq('Inaccessible label')
        expect(access).not_to have_access
        expect(access.loaded_at).not_to be_nil
      end

      it 'returns itself' do
        expect(access.load!).to eq(access)
      end

      it 'stores the result in redis' do
        Timecop.freeze do
          fake_cache = double
          expect(fake_cache).to receive(:store).with(true, nil, Time.now)
          expect(access).to receive(:cache).and_return(fake_cache)

          access.load!
        end
      end

      context 'when the request fails' do
        before do
          allow(fake_client).to receive(:request_access) do
            raise ::Gitlab::ExternalAuthorization::RequestFailed.new('Service unavailable')
          end
        end

        it 'is loaded' do
          access.load!

          expect(access).to be_loaded
        end

        it 'assigns the correct accessibility, reason and loaded_at' do
          access.load!

          expect(access.reason).to eq('Service unavailable')
          expect(access).not_to have_access
          expect(access.loaded_at).not_to be_nil
        end

        it 'does not store the result in redis' do
          fake_cache = double
          expect(fake_cache).not_to receive(:store)
          allow(access).to receive(:cache).and_return(fake_cache)

          access.load!
        end
      end
    end

    context 'When loading from cache' do
      let(:fake_cache) { double('ExternalAuthorization::Cache') }

      before do
        allow(access).to receive(:cache).and_return(fake_cache)
      end

      it 'does not load from the webservice' do
        Timecop.freeze do
          expect(fake_cache).to receive(:load).and_return([true, nil, Time.now])

          expect(access).to receive(:load_from_cache).and_call_original
          expect(access).not_to receive(:load_from_service)

          access.load!
        end
      end

      it 'loads from the webservice when the cached result was too old' do
        Timecop.freeze do
          expect(fake_cache).to receive(:load).and_return([true, nil, 2.days.ago])

          expect(access).to receive(:load_from_cache).and_call_original
          expect(access).to receive(:load_from_service).and_call_original
          allow(fake_cache).to receive(:store)

          access.load!
        end
      end
    end
  end
end
