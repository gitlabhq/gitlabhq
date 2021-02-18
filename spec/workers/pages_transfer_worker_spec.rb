# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesTransferWorker do
  describe '#perform' do
    Gitlab::PagesTransfer::METHODS.each do |meth|
      context "when method is #{meth}" do
        let(:args) { [1, 2, 3] }

        it 'calls the service with the given arguments' do
          expect_next_instance_of(Gitlab::PagesTransfer) do |service|
            expect(service).to receive(meth).with(*args).and_return(true)
          end

          subject.perform(meth, args)
        end

        it 'raises an error when the service returns false' do
          expect_next_instance_of(Gitlab::PagesTransfer) do |service|
            expect(service).to receive(meth).with(*args).and_return(false)
          end

          expect { subject.perform(meth, args) }
            .to raise_error(described_class::TransferFailedError)
        end
      end
    end

    describe 'when method is not allowed' do
      it 'does nothing' do
        expect(Gitlab::PagesTransfer).not_to receive(:new)

        subject.perform('object_id', [])
      end
    end
  end
end
