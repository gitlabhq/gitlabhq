# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::SidekiqStatus::ServerMiddleware do
  describe '#call' do
    let(:jid) { '123' }

    context 'when job is a success' do
      it 'stops tracking of a job upon completion' do
        expect(Gitlab::SidekiqStatus).to receive(:unset).with(jid)

        ret = described_class.new
          .call(double(:worker), { 'jid' => jid }, double(:queue)) { 10 }

        expect(ret).to eq(10)
      end
    end

    context 'when job raises an exception' do
      it 'stops tracking of a job upon completion' do
        expect(Gitlab::SidekiqStatus).to receive(:unset).with(jid)

        expect do
          described_class.new
            .call(double(:worker), { 'jid' => jid }, double(:queue)) { raise StandardError, "Failed" }
        end.to raise_error(StandardError, "Failed")
      end
    end
  end
end
