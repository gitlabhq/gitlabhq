# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Experimentation::ControllerConcern, type: :controller do
  controller(ApplicationController) do
    include Gitlab::Experimentation::ControllerConcern

    def index
      head :ok
    end
  end

  describe '#set_experimentation_subject_id_cookie' do
    before do
      get :index
    end

    context 'cookie is present' do
      before do
        cookies[:experimentation_subject_id] = 'test'
      end

      it 'does not change the cookie' do
        expect(cookies[:experimentation_subject_id]).to eq 'test'
      end
    end

    context 'cookie is not present' do
      it 'sets a permanent signed cookie' do
        expect(cookies.permanent.signed[:experimentation_subject_id]).to be_present
      end
    end
  end

  describe '#experiment_enabled?' do
    context 'cookie is not present' do
      it 'calls Gitlab::Experimentation.enabled? with the name of the experiment and an experimentation_subject_index of nil' do
        expect(Gitlab::Experimentation).to receive(:enabled?).with(:test_experiment, nil)
        controller.experiment_enabled?(:test_experiment)
      end
    end

    context 'cookie is present' do
      before do
        cookies.permanent.signed[:experimentation_subject_id] = 'abcd-1234'
        get :index
      end

      it 'calls Gitlab::Experimentation.enabled? with the name of the experiment and an experimentation_subject_index of the modulo 100 of the hex value of the uuid' do
        # 'abcd1234'.hex % 100 = 76
        expect(Gitlab::Experimentation).to receive(:enabled?).with(:test_experiment, 76)
        controller.experiment_enabled?(:test_experiment)
      end
    end
  end
end

describe Gitlab::Experimentation do
  before do
    stub_const('Gitlab::Experimentation::EXPERIMENTS', {
      test_experiment: {
        feature_toggle: feature_toggle,
        environment: environment,
        enabled_ratio: enabled_ratio
      }
    })

    stub_feature_flags(feature_toggle => true)
  end

  let(:feature_toggle) { :test_experiment_toggle }
  let(:environment) { Rails.env.test? }
  let(:enabled_ratio) { 0.1 }

  describe '.enabled?' do
    subject { described_class.enabled?(:test_experiment, experimentation_subject_index) }

    let(:experimentation_subject_index) { 9 }

    context 'feature toggle is enabled, we are on the right environment and we are selected' do
      it { is_expected.to be_truthy }
    end

    describe 'experiment is not defined' do
      it 'returns false' do
        expect(described_class.enabled?(:missing_experiment, experimentation_subject_index)).to be_falsey
      end
    end

    describe 'feature toggle' do
      context 'feature toggle is not set' do
        let(:feature_toggle) { nil }

        it { is_expected.to be_truthy }
      end

      context 'feature toggle is not set, but a feature with the experiment key as name does exist' do
        before do
          stub_feature_flags(test_experiment: false)
        end

        let(:feature_toggle) { nil }

        it { is_expected.to be_falsey }
      end

      context 'feature toggle is disabled' do
        before do
          stub_feature_flags(feature_toggle => false)
        end

        it { is_expected.to be_falsey }
      end
    end

    describe 'environment' do
      context 'environment is not set' do
        let(:environment) { nil }

        it { is_expected.to be_truthy }
      end

      context 'we are on the wrong environment' do
        let(:environment) { ::Gitlab.com? }

        it { is_expected.to be_falsey }
      end
    end

    describe 'enabled ratio' do
      context 'enabled ratio is not set' do
        let(:enabled_ratio) { nil }

        it { is_expected.to be_falsey }
      end

      context 'experimentation_subject_index is not set' do
        let(:experimentation_subject_index) { nil }

        it { is_expected.to be_falsey }
      end

      context 'experimentation_subject_index is an empty string' do
        let(:experimentation_subject_index) { '' }

        it { is_expected.to be_falsey }
      end

      context 'experimentation_subject_index outside enabled ratio' do
        let(:experimentation_subject_index) { 11 }

        it { is_expected.to be_falsey }
      end
    end
  end
end
