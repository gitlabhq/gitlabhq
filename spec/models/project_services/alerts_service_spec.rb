# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertsService do
  let_it_be(:project) { create(:project) }
  let(:service_params) { { project: project, active: active } }
  let(:active) { true }
  let(:service) { described_class.new(service_params) }

  shared_context 'when active' do
    let(:active) { true }
  end

  shared_context 'when inactive' do
    let(:active) { false }
  end

  shared_context 'when persisted' do
    before do
      service.save!
      service.reload
    end
  end

  describe '#url' do
    include Gitlab::Routing

    subject { service.url }

    it { is_expected.to eq(project_alerts_notify_url(project, format: :json)) }
  end

  describe '#json_fields' do
    subject { service.json_fields }

    it { is_expected.to eq(%w(active token)) }
  end

  describe '#as_json' do
    subject { service.as_json(only: service.json_fields) }

    it { is_expected.to eq('active' => true, 'token' => nil) }
  end

  describe '#token' do
    shared_context 'reset token' do
      before do
        service.token = ''
        service.valid?
      end
    end

    shared_context 'assign token' do |token|
      before do
        service.token = token
        service.valid?
      end
    end

    shared_examples 'valid token' do
      it { is_expected.to match(/\A\h{32}\z/) }
    end

    shared_examples 'no token' do
      it { is_expected.to be_blank }
    end

    subject { service.token }

    context 'when active' do
      include_context 'when active'

      context 'when resetting' do
        let!(:previous_token) { service.token }

        include_context 'reset token'

        it_behaves_like 'valid token'

        it { is_expected.not_to eq(previous_token) }
      end

      context 'when assigning' do
        include_context 'assign token', 'random token'

        it_behaves_like 'valid token'
      end
    end

    context 'when inactive' do
      include_context 'when inactive'

      context 'when resetting' do
        let!(:previous_token) { service.token }

        include_context 'reset token'

        it_behaves_like 'no token'
      end
    end

    context 'when persisted' do
      include_context 'when persisted'

      it_behaves_like 'valid token'
    end
  end
end
