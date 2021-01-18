# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Experimentation::ControllerConcern, type: :controller do
  before do
    stub_const('Gitlab::Experimentation::EXPERIMENTS', {
        backwards_compatible_test_experiment: {
          tracking_category: 'Team',
          use_backwards_compatible_subject_index: true
        },
        test_experiment: {
          tracking_category: 'Team'
        }
      }
    )

    Feature.enable_percentage_of_time(:backwards_compatible_test_experiment_experiment_percentage, enabled_percentage)
    Feature.enable_percentage_of_time(:test_experiment_experiment_percentage, enabled_percentage)
  end

  let(:enabled_percentage) { 10 }

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
        let(:do_not_track) { '0' }

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

  describe '#push_frontend_experiment' do
    it 'pushes an experiment to the frontend' do
      gon = instance_double('gon')
      stub_experiment_for_subject(my_experiment: true)
      allow(controller).to receive(:gon).and_return(gon)

      expect(gon).to receive(:push).with({ experiments: { 'myExperiment' => true } }, true)

      controller.push_frontend_experiment(:my_experiment)
    end
  end

  describe '#experiment_enabled?' do
    def check_experiment(exp_key = :test_experiment, subject = nil)
      controller.experiment_enabled?(exp_key, subject: subject)
    end

    subject { check_experiment }

    context 'cookie is not present' do
      it { is_expected.to eq(false) }
    end

    context 'cookie is present' do
      using RSpec::Parameterized::TableSyntax

      before do
        cookies.permanent.signed[:experimentation_subject_id] = 'abcd-1234'
        get :index
      end

      where(:experiment_key, :index_value) do
        :test_experiment | 'abcd-1234'
        :backwards_compatible_test_experiment | 'abcd1234'
      end

      with_them do
        it 'calls Gitlab::Experimentation.in_experiment_group?? with the name of the experiment and the calculated experimentation_subject_index based on the uuid' do
          expect(Gitlab::Experimentation).to receive(:in_experiment_group?).with(experiment_key, subject: index_value)

          check_experiment(experiment_key)
        end
      end

      context 'when subject is given' do
        let(:user) { build(:user) }

        it 'uses the subject' do
          expect(Gitlab::Experimentation).to receive(:in_experiment_group?).with(:test_experiment, subject: user)

          check_experiment(:test_experiment, user)
        end
      end
    end

    context 'do not track' do
      before do
        allow(Gitlab::Experimentation).to receive(:in_experiment_group?) { true }
      end

      context 'when do not track is disabled' do
        before do
          controller.request.headers['DNT'] = '0'
        end

        it { is_expected.to eq(true) }
      end

      context 'when do not track is enabled' do
        before do
          controller.request.headers['DNT'] = '1'
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'URL parameter to force enable experiment' do
      it 'returns true unconditionally' do
        get :index, params: { force_experiment: :test_experiment }

        is_expected.to eq(true)
      end
    end

    context 'Cookie parameter to force enable experiment' do
      it 'returns true unconditionally' do
        cookies[:force_experiment] = 'test_experiment,another_experiment'
        get :index

        expect(check_experiment(:test_experiment)).to eq(true)
        expect(check_experiment(:another_experiment)).to eq(true)
      end
    end
  end

  describe '#track_experiment_event', :snowplow do
    context 'when the experiment is enabled' do
      before do
        stub_experiment(test_experiment: true)
      end

      context 'the user is part of the experimental group' do
        before do
          stub_experiment_for_subject(test_experiment: true)
        end

        it 'tracks the event with the right parameters' do
          controller.track_experiment_event(:test_experiment, 'start', 1)

          expect_snowplow_event(
            category: 'Team',
            action: 'start',
            property: 'experimental_group',
            value: 1
          )
        end
      end

      context 'the user is part of the control group' do
        before do
          stub_experiment_for_subject(test_experiment: false)
        end

        it 'tracks the event with the right parameters' do
          controller.track_experiment_event(:test_experiment, 'start', 1)

          expect_snowplow_event(
            category: 'Team',
            action: 'start',
            property: 'control_group',
            value: 1
          )
        end
      end

      context 'do not track is disabled' do
        before do
          request.headers['DNT'] = '0'
        end

        it 'does track the event' do
          controller.track_experiment_event(:test_experiment, 'start', 1)

          expect_snowplow_event(
            category: 'Team',
            action: 'start',
            property: 'control_group',
            value: 1
          )
        end
      end

      context 'do not track enabled' do
        before do
          request.headers['DNT'] = '1'
        end

        it 'does not track the event' do
          controller.track_experiment_event(:test_experiment, 'start', 1)

          expect_no_snowplow_event
        end
      end

      context 'subject is provided' do
        before do
          stub_experiment_for_subject(test_experiment: false)
        end

        it "provides the subject's hashed global_id as label" do
          experiment_subject = double(:subject, to_global_id: 'abc')

          controller.track_experiment_event(:test_experiment, 'start', 1, subject: experiment_subject)

          expect_snowplow_event(
            category: 'Team',
            action: 'start',
            property: 'control_group',
            value: 1,
            label: Digest::MD5.hexdigest('abc')
          )
        end

        it "provides the subject's hashed string representation as label" do
          experiment_subject = 'somestring'

          controller.track_experiment_event(:test_experiment, 'start', 1, subject: experiment_subject)

          expect_snowplow_event(
            category: 'Team',
            action: 'start',
            property: 'control_group',
            value: 1,
            label: Digest::MD5.hexdigest('somestring')
          )
        end
      end

      context 'no subject is provided but cookie is set' do
        before do
          get :index
          stub_experiment_for_subject(test_experiment: false)
        end

        it 'uses the experimentation_subject_id as fallback' do
          controller.track_experiment_event(:test_experiment, 'start', 1)

          expect_snowplow_event(
            category: 'Team',
            action: 'start',
            property: 'control_group',
            value: 1,
            label: cookies.permanent.signed[:experimentation_subject_id]
          )
        end
      end
    end

    context 'when the experiment is disabled' do
      before do
        stub_experiment(test_experiment: false)
      end

      it 'does not track the event' do
        controller.track_experiment_event(:test_experiment, 'start')

        expect_no_snowplow_event
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
          stub_experiment_for_subject(test_experiment: true)
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
          stub_experiment_for_subject(test_experiment: false)
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

      context 'do not track disabled' do
        before do
          request.headers['DNT'] = '0'
        end

        it 'pushes the right parameters to gon' do
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

      context 'do not track enabled' do
        before do
          request.headers['DNT'] = '1'
        end

        it 'does not push data to gon' do
          controller.frontend_experimentation_tracking_data(:test_experiment, 'start')

          expect(Gon.method_defined?(:tracking_data)).to eq(false)
        end
      end
    end

    context 'when the experiment is disabled' do
      before do
        stub_experiment(test_experiment: false)
      end

      it 'does not push data to gon' do
        expect(Gon.method_defined?(:tracking_data)).to eq(false)
        controller.track_experiment_event(:test_experiment, 'start')
      end
    end
  end

  describe '#record_experiment_user' do
    let(:user) { build(:user) }
    let(:context) { { a: 42 } }

    context 'when the experiment is enabled' do
      before do
        stub_experiment(test_experiment: true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      context 'the user is part of the experimental group' do
        before do
          stub_experiment_for_subject(test_experiment: true)
        end

        it 'calls add_user on the Experiment model' do
          expect(::Experiment).to receive(:add_user).with(:test_experiment, :experimental, user, context)

          controller.record_experiment_user(:test_experiment, context)
        end
      end

      context 'the user is part of the control group' do
        before do
          stub_experiment_for_subject(test_experiment: false)
        end

        it 'calls add_user on the Experiment model' do
          expect(::Experiment).to receive(:add_user).with(:test_experiment, :control, user, context)

          controller.record_experiment_user(:test_experiment, context)
        end
      end
    end

    context 'when the experiment is disabled' do
      before do
        stub_experiment(test_experiment: false)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'does not call add_user on the Experiment model' do
        expect(::Experiment).not_to receive(:add_user)

        controller.record_experiment_user(:test_experiment, context)
      end
    end

    context 'when there is no current_user' do
      before do
        stub_experiment(test_experiment: true)
      end

      it 'does not call add_user on the Experiment model' do
        expect(::Experiment).not_to receive(:add_user)

        controller.record_experiment_user(:test_experiment, context)
      end
    end

    context 'do not track' do
      before do
        stub_experiment(test_experiment: true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      context 'is disabled' do
        before do
          request.headers['DNT'] = '0'
          stub_experiment_for_subject(test_experiment: false)
        end

        it 'calls add_user on the Experiment model' do
          expect(::Experiment).to receive(:add_user).with(:test_experiment, :control, user, context)

          controller.record_experiment_user(:test_experiment, context)
        end
      end

      context 'is enabled' do
        before do
          request.headers['DNT'] = '1'
        end

        it 'does not call add_user on the Experiment model' do
          expect(::Experiment).not_to receive(:add_user)

          controller.record_experiment_user(:test_experiment, context)
        end
      end
    end
  end

  describe '#record_experiment_conversion_event' do
    let(:user) { build(:user) }

    before do
      allow(controller).to receive(:dnt_enabled?).and_return(false)
      allow(controller).to receive(:current_user).and_return(user)
      stub_experiment(test_experiment: true)
    end

    subject(:record_conversion_event) do
      controller.record_experiment_conversion_event(:test_experiment)
    end

    it 'records the conversion event for the experiment & user' do
      expect(::Experiment).to receive(:record_conversion_event).with(:test_experiment, user)
      record_conversion_event
    end

    shared_examples 'does not record the conversion event' do
      it 'does not record the conversion event' do
        expect(::Experiment).not_to receive(:record_conversion_event)
        record_conversion_event
      end
    end

    context 'when DNT is enabled' do
      before do
        allow(controller).to receive(:dnt_enabled?).and_return(true)
      end

      include_examples 'does not record the conversion event'
    end

    context 'when there is no current user' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
      end

      include_examples 'does not record the conversion event'
    end

    context 'when the experiment is not enabled' do
      before do
        stub_experiment(test_experiment: false)
      end

      include_examples 'does not record the conversion event'
    end
  end

  describe '#experiment_tracking_category_and_group' do
    let_it_be(:experiment_key) { :test_something }

    subject { controller.experiment_tracking_category_and_group(experiment_key) }

    it 'returns a string with the experiment tracking category & group joined with a ":"' do
      expect(controller).to receive(:tracking_category).with(experiment_key).and_return('Experiment::Category')
      expect(controller).to receive(:tracking_group).with(experiment_key, '_group', subject: nil).and_return('experimental_group')

      expect(subject).to eq('Experiment::Category:experimental_group')
    end
  end
end
