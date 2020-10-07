# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::DestroyWorker do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before_all do
    project.add_maintainer(user)
  end

  subject { described_class.new }

  describe "#perform" do
    context 'with a Web hook' do
      let!(:hook) { create(:project_hook, project: project) }
      let!(:other_hook) { create(:project_hook, project: project) }
      let!(:log) { create(:web_hook_log, web_hook: hook) }
      let!(:other_log) { create(:web_hook_log, web_hook: other_hook) }

      it "deletes the Web hook and logs", :aggregate_failures do
        expect { subject.perform(user.id, hook.id) }
          .to change { WebHookLog.count }.from(2).to(1)
          .and change { WebHook.count }.from(2).to(1)

        expect(WebHook.find(other_hook.id)).to be_present
        expect(WebHookLog.find(other_log.id)).to be_present
      end

      it "raises and tracks an error if destroy failed" do
        allow_next_instance_of(::WebHooks::DestroyService) do |instance|
          expect(instance).to receive(:sync_destroy).with(anything).and_return({ status: :error, message: "failed" })
        end

        expect(Gitlab::ErrorTracking).to receive(:track_exception)
                                       .with(an_instance_of(::WebHooks::DestroyService::DestroyError), web_hook_id: hook.id)
                                       .and_call_original
        expect { subject.perform(user.id, hook.id) }.to raise_error(::WebHooks::DestroyService::DestroyError)
      end

      context 'with unknown hook' do
        it 'does not raise an error' do
          expect { subject.perform(user.id, non_existing_record_id) }.not_to raise_error

          expect(WebHook.count).to eq(2)
        end
      end

      context 'with unknown user' do
        it 'does not raise an error' do
          expect { subject.perform(non_existing_record_id, hook.id) }.not_to raise_error

          expect(WebHook.count).to eq(2)
        end
      end
    end
  end
end
