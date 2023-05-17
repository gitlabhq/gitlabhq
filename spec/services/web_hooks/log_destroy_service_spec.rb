# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::LogDestroyService, feature_category: :webhooks do
  subject(:service) { described_class.new(hook.id) }

  describe '#execute' do
    shared_examples 'deletes web hook logs for hook' do
      before do
        create_list(:web_hook_log, 3, web_hook: hook)
        hook.destroy! # The LogDestroyService is expected to be called _after_ hook destruction
      end

      it 'deletes the logs' do
        expect { service.execute }
          .to change(WebHookLog, :count).from(3).to(0)
      end

      context 'when the data-set exceeds the batch size' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 2)
        end

        it 'deletes the logs' do
          expect { service.execute }
            .to change(WebHookLog, :count).from(3).to(0)
        end
      end

      context 'when it encounters an error' do
        before do
          allow(WebHookLog).to receive(:delete_batch_for).and_raise(StandardError.new('bang'))
        end

        it 'reports the error' do
          expect(service.execute)
            .to be_error
            .and have_attributes(message: 'bang')
        end
      end
    end

    context 'with system hook' do
      let!(:hook) { create(:system_hook, url: "http://example.com") }

      it_behaves_like 'deletes web hook logs for hook'
    end

    context 'with project hook' do
      let!(:hook) { create(:project_hook) }

      it_behaves_like 'deletes web hook logs for hook'
    end
  end
end
