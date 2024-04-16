# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::HasWebHooks, feature_category: :webhooks do
  let(:minimal_test_class) do
    Class.new do
      include WebHooks::HasWebHooks

      def id
        1
      end
    end
  end

  before do
    stub_const('MinimalTestClass', minimal_test_class)
  end

  describe '#last_failure_redis_key' do
    subject { MinimalTestClass.new.last_failure_redis_key }

    it { is_expected.to eq('web_hooks:last_failure:minimal_test_class-1') }
  end

  describe 'last_webhook_failure', :clean_gitlab_redis_shared_state do
    subject { MinimalTestClass.new.last_webhook_failure }

    it { is_expected.to eq(nil) }

    context 'when there was an older failure', :clean_gitlab_redis_shared_state do
      let(:last_failure_date) { 1.month.ago.iso8601 }

      before do
        Gitlab::Redis::SharedState.with { |r| r.set('web_hooks:last_failure:minimal_test_class-1', last_failure_date) }
      end

      it { is_expected.to eq(last_failure_date) }
    end
  end

  describe '#update_last_webhook_failure', :clean_gitlab_redis_shared_state do
    let_it_be(:hook) { create(:project_hook) }
    let_it_be(:project) { hook.project }

    def last_failure
      Gitlab::Redis::SharedState.with do |redis|
        redis.get(project.last_failure_redis_key)
      end
    end

    def any_failed?
      Gitlab::Redis::SharedState.with do |redis|
        Gitlab::Utils.to_boolean(redis.get(project.web_hook_failure_redis_key))
      end
    end

    it 'is a method of this class' do
      expect { project.update_last_webhook_failure(hook) }.not_to raise_error
    end

    context 'when the hook is executable' do
      let(:redis_key) { project.web_hook_failure_redis_key }

      def redis_value
        any_failed?
      end

      context 'when the state was previously failing' do
        before do
          Gitlab::Redis::SharedState.with do |redis|
            redis.set(redis_key, true)
          end
        end

        it 'does update the state' do
          expect { project.update_last_webhook_failure(hook) }.to change { redis_value }.to(false)
        end

        context 'when there is another failing sibling hook' do
          before do
            create(:project_hook, :permanently_disabled, project: hook.project)
          end

          it 'does not update the state' do
            expect { project.update_last_webhook_failure(hook) }.not_to change { redis_value }.from(true)
          end

          it 'caches the current value' do
            Gitlab::Redis::SharedState.with do |redis|
              expect(redis).to receive(:set).with(redis_key, 'true', ex: 1.hour).and_call_original
            end

            project.update_last_webhook_failure(hook)
          end
        end
      end

      context 'when the state was previously unknown' do
        before do
          Gitlab::Redis::SharedState.with do |redis|
            redis.del(redis_key)
          end
        end

        it 'does not update the state' do
          expect { project.update_last_webhook_failure(hook) }.not_to change { redis_value }.from(nil)
        end
      end

      context 'when the state was previously not failing' do
        before do
          Gitlab::Redis::SharedState.with do |redis|
            redis.set(redis_key, false)
          end
        end

        it 'does not update the state' do
          expect { project.update_last_webhook_failure(hook) }.not_to change { redis_value }.from(false)
        end

        it 'does not cache the current value' do
          Gitlab::Redis::SharedState.with do |redis|
            expect(redis).not_to receive(:set)
          end

          project.update_last_webhook_failure(hook)
        end
      end
    end

    context 'when the hook is failed' do
      before do
        allow(hook).to receive(:executable?).and_return(false)
      end

      context 'and there is no prior value', :freeze_time do
        it 'updates last_failure' do
          expect { project.update_last_webhook_failure(hook) }.to change { last_failure }.to(Time.current)
        end

        it 'updates any_failed?' do
          expect { project.update_last_webhook_failure(hook) }.to change { any_failed? }.to(true)
        end
      end

      context 'when there is a prior last_failure, from before now' do
        it 'updates the state' do
          the_future = 1.minute.from_now
          project.update_last_webhook_failure(hook)

          travel_to(the_future) do
            expect { project.update_last_webhook_failure(hook) }.to change { last_failure }.to(the_future.iso8601)
          end
        end

        it 'does not change the failing state' do
          the_future = 1.minute.from_now
          project.update_last_webhook_failure(hook)

          travel_to(the_future) do
            expect { project.update_last_webhook_failure(hook) }.not_to change { any_failed? }.from(true)
          end
        end
      end

      context 'and there is a prior value, from after now' do
        it 'does not update the state' do
          the_past = 1.minute.ago

          project.update_last_webhook_failure(hook)

          travel_to(the_past) do
            expect { project.update_last_webhook_failure(hook) }.not_to change { last_failure }
          end
        end
      end
    end
  end
end
