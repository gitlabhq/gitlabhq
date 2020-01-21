# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Experimentation do
  before do
    stub_const('Gitlab::Experimentation::EXPERIMENTS', {
      test_experiment: {
        feature_toggle: feature_toggle,
        environment: environment,
        enabled_ratio: enabled_ratio,
        tracking_category: 'Team'
      }
    })

    stub_feature_flags(feature_toggle => true)
  end

  let(:feature_toggle) { :test_experiment_toggle }
  let(:environment) { Rails.env.test? }
  let(:enabled_ratio) { 0.1 }

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
        it 'calls Gitlab::Experimentation.enabled_for_user? with the name of the experiment and an experimentation_subject_index of nil' do
          expect(Gitlab::Experimentation).to receive(:enabled_for_user?).with(:test_experiment, nil)
          controller.experiment_enabled?(:test_experiment)
        end
      end

      context 'cookie is present' do
        before do
          cookies.permanent.signed[:experimentation_subject_id] = 'abcd-1234'
          get :index
        end

        it 'calls Gitlab::Experimentation.enabled_for_user? with the name of the experiment and an experimentation_subject_index of the modulo 100 of the hex value of the uuid' do
          # 'abcd1234'.hex % 100 = 76
          expect(Gitlab::Experimentation).to receive(:enabled_for_user?).with(:test_experiment, 76)
          controller.experiment_enabled?(:test_experiment)
        end
      end

      describe 'URL parameter to force enable experiment' do
        it 'returns true' do
          get :index, params: { force_experiment: :test_experiment }

          expect(controller.experiment_enabled?(:test_experiment)).to be_truthy
        end
      end
    end

    describe '#track_experiment_event' do
      context 'when the experiment is enabled' do
        before do
          stub_experiment(test_experiment: true)
        end

        context 'the user is part of the experimental group' do
          before do
            stub_experiment_for_user(test_experiment: true)
          end

          it 'tracks the event with the right parameters' do
            expect(Gitlab::Tracking).to receive(:event).with(
              'Team',
              'start',
              label: nil,
              property: 'experimental_group'
            )
            controller.track_experiment_event(:test_experiment, 'start')
          end
        end

        context 'the user is part of the control group' do
          before do
            stub_experiment_for_user(test_experiment: false)
          end

          it 'tracks the event with the right parameters' do
            expect(Gitlab::Tracking).to receive(:event).with(
              'Team',
              'start',
              label: nil,
              property: 'control_group'
            )
            controller.track_experiment_event(:test_experiment, 'start')
          end
        end
      end

      context 'when the experiment is disabled' do
        before do
          stub_experiment(test_experiment: false)
        end

        it 'does not track the event' do
          expect(Gitlab::Tracking).not_to receive(:event)
          controller.track_experiment_event(:test_experiment, 'start')
        end
      end
    end

    describe '#frontend_experimentation_tracking_data' do
      context 'when the experiment is enabled' do
        before do
          stub_experiment(test_experiment: true)
        end

        context 'the user is part of the experimental group' do
          before do
            stub_experiment_for_user(test_experiment: true)
          end

          it 'pushes the right parameters to gon' do
            controller.frontend_experimentation_tracking_data(:test_experiment, 'start')
            expect(Gon.tracking_data).to eq(
              {
                category: 'Team',
                action: 'start',
                label: nil,
                property: 'experimental_group'
              }
            )
          end
        end

        context 'the user is part of the control group' do
          before do
            allow_next_instance_of(described_class) do |instance|
              allow(instance).to receive(:experiment_enabled?).with(:test_experiment).and_return(false)
            end
          end

          it 'pushes the right parameters to gon' do
            controller.frontend_experimentation_tracking_data(:test_experiment, 'start')
            expect(Gon.tracking_data).to eq(
              {
                category: 'Team',
                action: 'start',
                label: nil,
                property: 'control_group'
              }
            )
          end
        end
      end

      context 'when the experiment is disabled' do
        before do
          stub_experiment(test_experiment: false)
        end

        it 'does not push data to gon' do
          expect(Gon.method_defined?(:tracking_data)).to be_falsey
          controller.track_experiment_event(:test_experiment, 'start')
        end
      end
    end
  end

  describe '.enabled?' do
    subject { described_class.enabled?(:test_experiment) }

    context 'feature toggle is enabled, we are on the right environment and we are selected' do
      it { is_expected.to be_truthy }
    end

    describe 'experiment is not defined' do
      it 'returns false' do
        expect(described_class.enabled?(:missing_experiment)).to be_falsey
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
  end

  describe '.enabled_for_user?' do
    subject { described_class.enabled_for_user?(:test_experiment, experimentation_subject_index) }

    let(:experimentation_subject_index) { 9 }

    context 'experiment is disabled' do
      before do
        allow(described_class).to receive(:enabled?).and_return(false)
      end

      it { is_expected.to be_falsey }
    end

    context 'experiment is enabled' do
      before do
        allow(described_class).to receive(:enabled?).and_return(true)
      end

      it { is_expected.to be_truthy }

      context 'enabled ratio is not set' do
        let(:enabled_ratio) { nil }

        it { is_expected.to be_falsey }
      end

      describe 'experimentation_subject_index' do
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
end
