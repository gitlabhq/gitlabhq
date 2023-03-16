# frozen_string_literal: true

RSpec.shared_examples 'something that has web-hooks' do
  describe '#any_hook_failed?', :clean_gitlab_redis_shared_state do
    subject { object.any_hook_failed? }

    context 'when there are no hooks' do
      it { is_expected.to eq(false) }
    end

    context 'when there are hooks' do
      before do
        create_hook
        create_hook
      end

      it { is_expected.to eq(false) }

      context 'when there is a failed hook' do
        before do
          hook = create_hook
          hook.update!(recent_failures: WebHooks::AutoDisabling::FAILURE_THRESHOLD + 1)
        end

        it { is_expected.to eq(true) }
      end
    end
  end

  describe '#cache_web_hook_failure', :clean_gitlab_redis_shared_state do
    context 'when no value is passed' do
      it 'stores the return value of #any_hook_failed? and passes it back' do
        allow(object).to receive(:any_hook_failed?).and_return(true)

        Gitlab::Redis::SharedState.with do |r|
          expect(r).to receive(:set)
            .with(object.web_hook_failure_redis_key, 'true', ex: 1.hour)
            .and_call_original
        end

        expect(object.cache_web_hook_failure).to eq(true)
      end
    end

    context 'when a value is passed' do
      it 'stores the value and passes it back' do
        expect(object).not_to receive(:any_hook_failed?)

        Gitlab::Redis::SharedState.with do |r|
          expect(r).to receive(:set)
            .with(object.web_hook_failure_redis_key, 'foo', ex: 1.hour)
            .and_call_original
        end

        expect(object.cache_web_hook_failure(:foo)).to eq(:foo)
      end
    end
  end

  describe '#get_web_hook_failure', :clean_gitlab_redis_shared_state do
    subject { object.get_web_hook_failure }

    context 'when no value is stored' do
      it { is_expected.to be_nil }
    end

    context 'when stored as true' do
      before do
        object.cache_web_hook_failure(true)
      end

      it { is_expected.to eq(true) }
    end

    context 'when stored as false' do
      before do
        object.cache_web_hook_failure(false)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#fetch_web_hook_failure', :clean_gitlab_redis_shared_state do
    context 'when a value has not been stored' do
      it 'calls #any_hook_failed?' do
        expect(object.get_web_hook_failure).to be_nil
        expect(object).to receive(:any_hook_failed?).and_return(true)

        expect(object.fetch_web_hook_failure).to eq(true)
        expect(object.get_web_hook_failure).to eq(true)
      end
    end

    context 'when a value has been stored' do
      before do
        object.cache_web_hook_failure(true)
      end

      it 'does not call #any_hook_failed?' do
        expect(object).not_to receive(:any_hook_failed?)

        expect(object.fetch_web_hook_failure).to eq(true)
      end
    end
  end
end
