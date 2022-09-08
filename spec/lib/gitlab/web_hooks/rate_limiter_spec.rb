# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WebHooks::RateLimiter, :clean_gitlab_redis_rate_limiting do
  let_it_be(:plan) { create(:default_plan) }
  let_it_be_with_reload(:project_hook) { create(:project_hook) }
  let_it_be_with_reload(:system_hook) { create(:system_hook) }
  let_it_be_with_reload(:integration_hook) { create(:jenkins_integration).service_hook }
  let_it_be(:limit) { 1 }

  using RSpec::Parameterized::TableSyntax

  describe '#rate_limit!' do
    def rate_limit!(hook)
      described_class.new(hook).rate_limit!
    end

    shared_examples 'a hook that is never rate limited' do
      specify do
        expect(Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)

        expect(rate_limit!(hook)).to eq(false)
      end
    end

    context 'when there is no plan limit' do
      where(:hook) { [ref(:project_hook), ref(:system_hook), ref(:integration_hook)] }

      with_them { it_behaves_like 'a hook that is never rate limited' }
    end

    context 'when there is a plan limit' do
      before_all do
        create(:plan_limits, plan: plan, web_hook_calls: limit)
      end

      where(:hook, :limitless_hook_type) do
        ref(:project_hook)     | false
        ref(:system_hook)      | true
        ref(:integration_hook) | true
      end

      with_them do
        if params[:limitless_hook_type]
          it_behaves_like 'a hook that is never rate limited'
        else
          it 'rate limits the hook, returning true when rate limited' do
            expect(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
              .exactly(3).times
              .and_call_original

            freeze_time do
              limit.times { expect(rate_limit!(hook)).to eq(false) }
              expect(rate_limit!(hook)).to eq(true)
            end

            travel_to(1.day.from_now) do
              expect(rate_limit!(hook)).to eq(false)
            end
          end
        end
      end
    end

    describe 'rate limit scope' do
      it 'rate limits all hooks from the same namespace', :freeze_time do
        create(:plan_limits, plan: plan, web_hook_calls: limit)
        project_hook_in_different_namespace = create(:project_hook)
        project_hook_in_same_namespace = create(:project_hook,
          project: create(:project, namespace: project_hook.project.namespace)
        )

        limit.times { expect(rate_limit!(project_hook)).to eq(false) }
        expect(rate_limit!(project_hook)).to eq(true)
        expect(rate_limit!(project_hook_in_same_namespace)).to eq(true)
        expect(rate_limit!(project_hook_in_different_namespace)).to eq(false)
      end
    end
  end

  describe '#rate_limited?' do
    subject { described_class.new(hook).rate_limited? }

    context 'when no plan limit has been defined' do
      where(:hook) { [ref(:project_hook), ref(:system_hook), ref(:integration_hook)] }

      with_them do
        it { is_expected.to eq(false) }
      end
    end

    context 'when there is a plan limit' do
      before_all do
        create(:plan_limits, plan: plan, web_hook_calls: limit)
      end

      context 'when hook is not rate-limited' do
        where(:hook) { [ref(:project_hook), ref(:system_hook), ref(:integration_hook)] }

        with_them do
          it { is_expected.to eq(false) }
        end
      end

      context 'when hook is rate-limited' do
        before do
          allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)
        end

        where(:hook, :limitless_hook_type) do
          ref(:project_hook)     | false
          ref(:system_hook)      | true
          ref(:integration_hook) | true
        end

        with_them do
          it { is_expected.to eq(!limitless_hook_type) }
        end
      end
    end
  end
end
