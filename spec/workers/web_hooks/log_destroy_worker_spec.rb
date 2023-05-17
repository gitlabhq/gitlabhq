# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::LogDestroyWorker, feature_category: :integrations do
  include AfterNextHelpers

  let_it_be(:project) { create(:project) }

  subject { described_class.new }

  describe "#perform" do
    let!(:hook) { create(:project_hook, project: project) }
    let!(:other_hook) { create(:project_hook, project: project) }
    let!(:log) { create(:web_hook_log, web_hook: hook) }
    let!(:other_log) { create(:web_hook_log, web_hook: other_hook) }

    context 'with a Web hook' do
      it "deletes the relevant logs", :aggregate_failures do
        hook.destroy! # It does not depend on the presence of the hook

        expect { subject.perform({ 'hook_id' => hook.id }) }
          .to change { WebHookLog.count }.by(-1)

        expect(WebHook.find(other_hook.id)).to be_present
        expect(WebHookLog.find(other_log.id)).to be_present
      end

      it 'is idempotent' do
        subject.perform({ 'hook_id' => hook.id })
        subject.perform({ 'hook_id' => hook.id })

        expect(hook.web_hook_logs).to be_none
      end

      it "raises and tracks an error if destroy failed" do
        expect_next(::WebHooks::LogDestroyService)
          .to receive(:execute).and_return(ServiceResponse.error(message: "failed"))

        expect(Gitlab::ErrorTracking)
          .to receive(:track_and_raise_exception)
          .with(an_instance_of(described_class::DestroyError), { web_hook_id: hook.id })
          .and_call_original

        expect { subject.perform({ 'hook_id' => hook.id }) }
          .to raise_error(described_class::DestroyError)
      end

      context 'with extra arguments' do
        it 'does not raise an error' do
          expect { subject.perform({ 'hook_id' => hook.id, 'extra' => true }) }.not_to raise_error

          expect(WebHook.count).to eq(2)
          expect(WebHookLog.count).to eq(1)
        end
      end
    end

    context 'with no arguments' do
      it 'does not raise an error' do
        expect { subject.perform }.not_to raise_error

        expect(WebHook.count).to eq(2)
        expect(WebHookLog.count).to eq(2)
      end
    end

    context 'with empty arguments' do
      it 'does not raise an error' do
        expect { subject.perform({}) }.not_to raise_error

        expect(WebHook.count).to eq(2)
        expect(WebHookLog.count).to eq(2)
      end
    end

    context 'with unknown hook' do
      it 'does not raise an error' do
        expect { subject.perform({ 'hook_id' => non_existing_record_id }) }.not_to raise_error

        expect(WebHook.count).to eq(2)
        expect(WebHookLog.count).to eq(2)
      end
    end
  end
end
