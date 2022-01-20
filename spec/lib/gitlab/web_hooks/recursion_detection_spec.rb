# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WebHooks::RecursionDetection, :clean_gitlab_redis_shared_state, :request_store do
  let_it_be(:web_hook) { create(:project_hook) }

  let!(:uuid_class) { described_class::UUID }

  describe '.set_from_headers' do
    let(:old_uuid) { SecureRandom.uuid }
    let(:rack_headers) { Rack::MockRequest.env_for("/").merge(headers) }

    subject(:set_from_headers) { described_class.set_from_headers(rack_headers) }

    # Note, having a previous `request_uuid` value set before `.set_from_headers` is
    # called is contrived and should not normally happen. However, testing with this scenario
    # allows us to assert the ideal outcome if it ever were to happen.
    before do
      uuid_class.instance.request_uuid = old_uuid
    end

    context 'when the detection header is present' do
      let(:new_uuid) { SecureRandom.uuid }

      let(:headers) do
        { uuid_class::HEADER => new_uuid }
      end

      it 'sets the request UUID value from the headers' do
        set_from_headers

        expect(uuid_class.instance.request_uuid).to eq(new_uuid)
      end
    end

    context 'when detection header is not present' do
      let(:headers) { {} }

      it 'does not set the request UUID' do
        set_from_headers

        expect(uuid_class.instance.request_uuid).to eq(old_uuid)
      end
    end
  end

  describe '.set_request_uuid' do
    it 'sets the request UUID value' do
      new_uuid = SecureRandom.uuid

      described_class.set_request_uuid(new_uuid)

      expect(uuid_class.instance.request_uuid).to eq(new_uuid)
    end
  end

  describe '.register!' do
    let_it_be(:second_web_hook) { create(:project_hook) }
    let_it_be(:third_web_hook) { create(:project_hook) }

    def cache_key(hook)
      described_class.send(:cache_key_for_hook, hook)
    end

    it 'stores IDs in the same cache when a request UUID is set, until the request UUID changes', :aggregate_failures do
      # Register web_hook and second_web_hook against the same request UUID.
      uuid_class.instance.request_uuid = SecureRandom.uuid
      described_class.register!(web_hook)
      described_class.register!(second_web_hook)
      first_cache_key = cache_key(web_hook)
      second_cache_key = cache_key(second_web_hook)

      # Register third_web_hook against a new request UUID.
      uuid_class.instance.request_uuid = SecureRandom.uuid
      described_class.register!(third_web_hook)
      third_cache_key = cache_key(third_web_hook)

      expect(first_cache_key).to eq(second_cache_key)
      expect(second_cache_key).not_to eq(third_cache_key)

      ::Gitlab::Redis::SharedState.with do |redis|
        members = redis.smembers(first_cache_key).map(&:to_i)
        expect(members).to contain_exactly(web_hook.id, second_web_hook.id)

        members = redis.smembers(third_cache_key).map(&:to_i)
        expect(members).to contain_exactly(third_web_hook.id)
      end
    end

    it 'stores IDs in unique caches when no request UUID is present', :aggregate_failures do
      described_class.register!(web_hook)
      described_class.register!(second_web_hook)
      described_class.register!(third_web_hook)

      first_cache_key = cache_key(web_hook)
      second_cache_key = cache_key(second_web_hook)
      third_cache_key = cache_key(third_web_hook)

      expect([first_cache_key, second_cache_key, third_cache_key].compact.length).to eq(3)

      ::Gitlab::Redis::SharedState.with do |redis|
        members = redis.smembers(first_cache_key).map(&:to_i)
        expect(members).to contain_exactly(web_hook.id)

        members = redis.smembers(second_cache_key).map(&:to_i)
        expect(members).to contain_exactly(second_web_hook.id)

        members = redis.smembers(third_cache_key).map(&:to_i)
        expect(members).to contain_exactly(third_web_hook.id)
      end
    end

    it 'touches the storage ttl each time it is called', :aggregate_failures do
      freeze_time do
        described_class.register!(web_hook)

        ::Gitlab::Redis::SharedState.with do |redis|
          expect(redis.ttl(cache_key(web_hook))).to eq(described_class::TOUCH_CACHE_TTL.to_i)
        end
      end

      travel_to(1.minute.from_now) do
        described_class.register!(second_web_hook)

        ::Gitlab::Redis::SharedState.with do |redis|
          expect(redis.ttl(cache_key(web_hook))).to eq(described_class::TOUCH_CACHE_TTL.to_i)
        end
      end
    end
  end

  describe 'block?' do
    let_it_be(:registered_web_hooks) { create_list(:project_hook, 2) }

    subject(:block?) { described_class.block?(web_hook) }

    before do
      # Register some previous webhooks.
      uuid_class.instance.request_uuid = SecureRandom.uuid

      registered_web_hooks.each do |web_hook|
        described_class.register!(web_hook)
      end
    end

    it 'returns false if webhook should not be blocked' do
      is_expected.to eq(false)
    end

    context 'when the webhook has previously fired' do
      before do
        described_class.register!(web_hook)
      end

      it 'returns true' do
        is_expected.to eq(true)
      end

      context 'when the request UUID changes again' do
        before do
          uuid_class.instance.request_uuid = SecureRandom.uuid
        end

        it 'returns false' do
          is_expected.to eq(false)
        end
      end
    end

    context 'when the count limit has been reached' do
      let_it_be(:registered_web_hooks) { create_list(:project_hook, 2) }

      before do
        registered_web_hooks.each do |web_hook|
          described_class.register!(web_hook)
        end

        stub_const("#{described_class.name}::COUNT_LIMIT", registered_web_hooks.size)
      end

      it 'returns true' do
        is_expected.to eq(true)
      end

      context 'when the request UUID changes again' do
        before do
          uuid_class.instance.request_uuid = SecureRandom.uuid
        end

        it 'returns false' do
          is_expected.to eq(false)
        end
      end
    end
  end

  describe '.header' do
    subject(:header) { described_class.header(web_hook) }

    it 'returns a header with the UUID value' do
      uuid = SecureRandom.uuid
      allow(uuid_class.instance).to receive(:uuid_for_hook).and_return(uuid)

      is_expected.to eq({ uuid_class::HEADER => uuid })
    end
  end

  describe '.to_log' do
    subject(:to_log) { described_class.to_log(web_hook) }

    it 'returns the UUID value and all registered webhook IDs in a Hash' do
      uuid = SecureRandom.uuid
      allow(uuid_class.instance).to receive(:uuid_for_hook).and_return(uuid)
      registered_web_hooks = create_list(:project_hook, 2)
      registered_web_hooks.each { described_class.register!(_1) }

      is_expected.to eq({ uuid: uuid, ids: registered_web_hooks.map(&:id) })
    end
  end
end
