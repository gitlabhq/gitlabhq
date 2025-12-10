# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerControllerToken, feature_category: :continuous_integration do
  let(:runner_controller) { create(:ci_runner_controller) }

  describe 'associations' do
    it { is_expected.to belong_to(:runner_controller).class_name('Ci::RunnerController') }
  end

  describe 'validations' do
    subject(:token) { create(:ci_runner_controller_token) }

    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
  end

  describe 'token' do
    it 'uses TokenAuthenticatable' do
      expect(described_class.token_authenticatable_fields).to include(:token)
    end

    it 'has the correct token prefix' do
      token = create(:ci_runner_controller_token, runner_controller: runner_controller)

      expect(token.token).to start_with('glrct-')
    end
  end

  describe 'callbacks' do
    it 'calls ensure_token before create' do
      token = build(:ci_runner_controller_token, runner_controller: runner_controller)

      expect(token).to receive(:ensure_token).and_call_original
      token.save!
    end
  end
end
