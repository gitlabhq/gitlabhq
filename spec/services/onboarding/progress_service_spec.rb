# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::ProgressService, feature_category: :onboarding do
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
