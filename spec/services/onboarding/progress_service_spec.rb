# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::ProgressService, feature_category: :onboarding do
  describe '.async' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:action) { :git_write }

    subject(:execute_service) { described_class.async(namespace.id).execute(action: action) }

    context 'when not onboarded' do
      it 'does not schedule a worker' do
        expect(Onboarding::ProgressWorker).not_to receive(:perform_async)

        execute_service
      end
    end

    context 'when onboarded' do
      before do
        Onboarding::Progress.onboard(namespace)
      end

      context 'when action is already completed' do
        before do
          Onboarding::Progress.register(namespace, action)
        end

        it 'does not schedule a worker' do
          expect(Onboarding::ProgressWorker).not_to receive(:perform_async)

          execute_service
        end
      end

      context 'when action is not yet completed' do
        it 'schedules a worker' do
          expect(Onboarding::ProgressWorker).to receive(:perform_async)

          execute_service
        end
      end
    end
  end

  describe '#execute' do
    let(:namespace) { create(:namespace) }
    let(:action) { :namespace_action }

    subject(:execute_service) { described_class.new(namespace).execute(action: :merge_request_created) }

    context 'when the namespace is a root' do
      before do
        Onboarding::Progress.onboard(namespace)
      end

      it 'registers a namespace onboarding progress action for the given namespace' do
        execute_service

        expect(Onboarding::Progress.completed?(namespace, :merge_request_created)).to eq(true)
      end
    end

    context 'when the namespace is not the root' do
      let(:group) { create(:group, :nested) }

      before do
        Onboarding::Progress.onboard(group)
      end

      it 'does not register a namespace onboarding progress action' do
        execute_service

        expect(Onboarding::Progress.completed?(group, :merge_request_created)).to be(false)
      end
    end

    context 'when no namespace is passed' do
      let(:namespace) { nil }

      it 'does not register a namespace onboarding progress action' do
        execute_service

        expect(Onboarding::Progress.completed?(namespace, :merge_request_created)).to be(false)
      end
    end
  end
end
