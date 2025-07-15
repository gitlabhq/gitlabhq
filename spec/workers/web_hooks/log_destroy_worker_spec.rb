# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::LogDestroyWorker, feature_category: :integrations do
  subject(:worker) { described_class.new }

  describe "#perform" do
    it 'no-ops' do
      expect { worker.perform({ 'hook_id' => 123 }) }.not_to raise_error
    end

    context 'with no arguments' do
      it 'does not raise an error' do
        expect { worker.perform }.not_to raise_error
      end
    end

    context 'with extra arguments' do
      it 'does not raise an error' do
        expect { worker.perform({ 'hook_id' => 123, 'extra' => true }) }.not_to raise_error
      end
    end

    context 'with empty arguments' do
      it 'does not raise an error' do
        expect { worker.perform({}) }.not_to raise_error
      end
    end
  end
end
