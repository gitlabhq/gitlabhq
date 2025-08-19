# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::MemberLimitCheckService, feature_category: :importers do
  let(:service) { described_class.new(importable) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, namespace: group) }

  describe '#execute' do
    subject(:service_response) { service.execute }

    context 'when importable is a Project' do
      let(:importable) { project }

      it 'returns success' do
        expect(service_response).to be_success
      end
    end

    context 'when importable is a Group' do
      let(:importable) { group }

      it 'returns success' do
        expect(service_response).to be_success
      end
    end

    context 'when importable is neither Project nor Group' do
      let(:importable) { build(:user) }

      it 'returns error with message' do
        expect(service_response).to be_error
        expect(service_response.message).to eq('importable must be a Group or Project')
      end
    end

    context 'when importable is nil' do
      let(:importable) { nil }

      it 'returns error with message' do
        expect(service_response).to be_error
        expect(service_response.message).to eq('importable must be a Group or Project')
      end
    end
  end
end
