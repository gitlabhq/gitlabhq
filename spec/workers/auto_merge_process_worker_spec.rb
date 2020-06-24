# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoMergeProcessWorker do
  describe '#perform' do
    subject { described_class.new.perform(merge_request&.id) }

    context 'when merge request is found' do
      let(:merge_request) { create(:merge_request) }

      it 'executes AutoMergeService' do
        expect_next_instance_of(AutoMergeService) do |auto_merge|
          expect(auto_merge).to receive(:process)
        end

        subject
      end
    end

    context 'when merge request is not found' do
      let(:merge_request) { nil }

      it 'does not execute AutoMergeService' do
        expect(AutoMergeService).not_to receive(:new)

        subject
      end
    end
  end
end
