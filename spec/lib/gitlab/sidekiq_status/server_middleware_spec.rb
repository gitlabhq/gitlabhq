# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqStatus::ServerMiddleware do
  describe '#call' do
    it 'stops tracking of a job upon completion' do
      expect(Gitlab::SidekiqStatus).to receive(:unset).with('123')

      ret = described_class.new
        .call(double(:worker), { 'jid' => '123' }, double(:queue)) { 10 }

      expect(ret).to eq(10)
    end
  end
end
