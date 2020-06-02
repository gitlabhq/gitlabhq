# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Experimentation do
  before do
    stub_const('Gitlab::Experimentation::EXPERIMENTS', {
      test_experiment: {
        environment: environment,
        tracking_category: 'Team'
      }
    })

    Feature.enable_percentage_of_time(:test_experiment_experiment_percentage, enabled_percentage)
  end

  let(:environment) { Rails.env.test? }
  let(:enabled_percentage) { 10 }

  describe Gitlab::Experimentation::ControllerConcern, type: :controller do
    controller(ApplicationController) do
      include Gitlab::Experimentation::ControllerConcern

      def index
        head :ok
      end
    end

    describe '#set_experimentation_subject_id_cookie' do
      let(:do_not_track) { nil }
      let(:cookie) { cookies.permanent.signed[:experimentation_subject_id] }

      before do
        request.headers['DNT'] = do_not_track if do_not_track.present?

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
          expect(cookie).to be_present
        end

        context 'DNT: 0' do
          let(:do_not_Track) { '0' }

          it 'sets a permanent signed cookie' do
            expect(cookie).to be_present
          end
        end

        context 'DNT: 1' do
          let(:do_not_track) { '1' }

          it 'does nothing' do
            expect(cookie).not_to be_present
          end
        end
      end
    end

    describe '#experiment_enabled?' do
      subject { controller.experiment_enabled?(:test_experiment) }

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

      it 'returns true when DNT: 0 is set in the request' do
        allow(Gitlab::Experimentation).to receive(:enabled_for_user?) { true }
        controller.request.headers['DNT'] = '0'

        is_expected.to be_truthy
      end

      it 'returns false when DNT: 1 is set in the request' do
        allow(Gitlab::Experimentation).to receive(:enabled_for_user?) { true }
        controller.request.headers['DNT'] = '1'

        is_expected.to be_falsy
      end

      describe 'URL parameter to force enable experiment' do
        it 'returns true unconditionally' do
          get :index, params: { force_experiment: :test_experiment }

          is_expected.to be_truthy
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
              property: 'experimental_group',
              value: 'team_id'
            )
            controller.track_experiment_event(:test_experiment, 'start', 'team_id')
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
              property: 'control_group',
              value: 'team_id'
            )
            controller.track_experiment_event(:test_experiment, 'start', 'team_id')
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
            controller.frontend_experimentation_tracking_data(:test_experiment, 'start', 'team_id')
            expect(Gon.tracking_data).to eq(
              {
                category: 'Team',
                action: 'start',
                property: 'experimental_group',
                value: 'team_id'
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
            controller.frontend_experimentation_tracking_data(:test_experiment, 'start', 'team_id')
            expect(Gon.tracking_data).to eq(
              {
                category: 'Team',
                action: 'start',
                property: 'control_group',
                value: 'team_id'
              }
            )
          end

          it 'does not send nil value to gon' do
            controller.frontend_experimentation_tracking_data(:test_experiment, 'start')
            expect(Gon.tracking_data).to eq(
              {
                category: 'Team',
                action: 'start',
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

    describe 'experiment is disabled' do
      let(:enabled_percentage) { 0 }

      it { is_expected.to be_falsey }
    end

    describe 'we are on the wrong environment' do
      let(:environment) { ::Gitlab.com? }

      it { is_expected.to be_falsey }
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
