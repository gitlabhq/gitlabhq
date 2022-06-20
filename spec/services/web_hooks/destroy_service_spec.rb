# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::DestroyService do
  let_it_be(:user) { create(:user) }

  subject { described_class.new(user) }

  describe '#execute' do
    %i[system_hook project_hook].each do |factory|
      context "deleting a #{factory}" do
        let!(:hook) { create(factory) } # rubocop: disable Rails/SaveBang (false-positive!)
        let!(:log) { create_list(:web_hook_log, 3, web_hook: hook) }

        it 'is successful' do
          expect(subject.execute(hook)).to be_success
        end

        it 'destroys the hook' do
          expect { subject.execute(hook) }.to change(WebHook, :count).from(1).to(0)
        end

        it 'does not destroy logs' do
          expect { subject.execute(hook) }.not_to change(WebHookLog, :count)
        end

        it 'schedules the destruction of logs' do
          expect(WebHooks::LogDestroyWorker).to receive(:perform_async).with({ 'hook_id' => hook.id })
          expect(Gitlab::AppLogger).to receive(:info).with(match(/scheduled a deletion of logs/))

          subject.execute(hook)
        end

        context 'when the hook fails to destroy' do
          before do
            allow(hook).to receive(:destroy).and_return(false)
          end

          it 'is not a success' do
            expect(WebHooks::LogDestroyWorker).not_to receive(:perform_async)

            r = subject.execute(hook)

            expect(r).to be_error
            expect(r[:message]).to match %r{Unable to destroy}
          end
        end
      end
    end
  end
end
