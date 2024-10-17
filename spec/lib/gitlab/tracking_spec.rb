# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Tracking, feature_category: :application_instrumentation do
  include StubENV
  using RSpec::Parameterized::TableSyntax

  before do
    stub_application_setting(snowplow_enabled: true)
    stub_application_setting(snowplow_collector_hostname: 'gitfoo.com')
    stub_application_setting(snowplow_cookie_domain: '.gitfoo.com')
    stub_application_setting(snowplow_app_id: '_abc123_')

    described_class.instance_variable_set(:@tracker, nil)
  end

  after do
    described_class.instance_variable_set(:@tracker, nil)
  end

  it { is_expected.to delegate_method(:flush).to(:tracker) }

  describe '.options' do
    shared_examples 'delegates to destination' do |klass|
      before do
        allow_next_instance_of(klass) do |instance|
          allow(instance).to receive(:options).and_call_original
        end
      end

      it "delegates to #{klass} destination" do
        expect_next_instance_of(klass) do |instance|
          expect(instance).to receive(:options)
        end

        subject.options(nil)
      end
    end

    shared_examples 'delegates to SnowplowMicro destination with proper options' do
      it_behaves_like 'delegates to destination', Gitlab::Tracking::Destinations::SnowplowMicro

      it 'returns useful client options' do
        expected_fields = {
          namespace: 'gl',
          hostname: 'localhost:9090',
          cookieDomain: '.gitlab.com',
          appId: '_abc123_',
          protocol: 'http',
          port: 9090,
          forceSecureTracker: false,
          formTracking: true,
          linkClickTracking: true
        }

        expect(subject.options(nil)).to match(expected_fields)
      end
    end

    context 'when destination is Snowplow' do
      it_behaves_like 'delegates to destination', Gitlab::Tracking::Destinations::Snowplow

      it 'returns useful client options' do
        expected_fields = {
          namespace: 'gl',
          hostname: 'gitfoo.com',
          cookieDomain: '.gitfoo.com',
          appId: '_abc123_',
          formTracking: true,
          linkClickTracking: true
        }

        expect(subject.options(nil)).to match(expected_fields)
      end
    end

    context 'when destination is SnowplowMicro' do
      before do
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      context "enabled with yml config" do
        let(:snowplow_micro_settings) do
          {
            enabled: true,
            address: "localhost:9090"
          }
        end

        before do
          stub_config(snowplow_micro: snowplow_micro_settings)
        end

        it_behaves_like 'delegates to SnowplowMicro destination with proper options'
      end
    end

    it 'when feature flag is disabled' do
      stub_feature_flags(additional_snowplow_tracking: false)

      expect(subject.options(nil)).to include(
        formTracking: false,
        linkClickTracking: false
      )
    end
  end

  context 'event tracking' do
    let(:namespace) { create(:namespace) }

    shared_examples 'rescued error raised by destination class' do
      it 'rescues error' do
        error = StandardError.new("something went wrong")
        allow_any_instance_of(destination_class).to receive(:event).and_raise(error)

        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
                                           .with(
                                             error,
                                             snowplow_category: category,
                                             snowplow_action: action
                                           )

        expect { tracking_method }.not_to raise_error
      end
    end

    shared_examples 'delegates to destination' do |klass, method|
      before do
        allow_any_instance_of(klass).to receive(:event)
      end

      it "delegates to #{klass} destination" do
        other_context = double(:context)

        project = build_stubbed(:project)
        user = build_stubbed(:user)

        expect(Gitlab::Tracking::StandardContext)
          .to receive(:new)
                .with(project_id: project.id, user: user, namespace_id: namespace.id, plan_name: namespace.actual_plan_name, extra_key_1: 'extra value 1', extra_key_2: 'extra value 2')
                .and_call_original

        expect_any_instance_of(klass).to receive(:event) do |_, category, action, args|
          expect(category).to eq('category')
          expect(action).to eq('action')
          expect(args[:label]).to eq('label')
          expect(args[:property]).to eq('property')
          expect(args[:value]).to eq(1.5)
          expect(args[:context].length).to eq(2)
          expect(args[:context].first.to_json[:schema]).to eq(Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL)
          expect(args[:context].last).to eq(other_context)
        end

        described_class.method(method).call('category', 'action',
          label: 'label',
          property: 'property',
          value: 1.5,
          context: [other_context],
          project: project,
          user: user,
          namespace: namespace,
          extra_key_1: 'extra value 1',
          extra_key_2: 'extra value 2'
        )
      end
    end

    describe '.event' do
      context 'when the action is not passed in as a string' do
        it 'allows symbols' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

          described_class.event('category', :some_action)
        end

        it 'allows nil' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

          described_class.event('category', nil)
        end

        it 'allows integers' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

          described_class.event('category', 1)
        end
      end

      context 'when destination is Snowplow' do
        before do
          allow(Rails.env).to receive(:development?).and_return(true)
        end

        it_behaves_like 'rescued error raised by destination class' do
          let(:category) { 'category' }
          let(:action) { 'action' }
          let(:destination_class) { Gitlab::Tracking::Destinations::Snowplow }

          subject(:tracking_method) { described_class.event(category, action) }
        end

        it_behaves_like 'delegates to destination', Gitlab::Tracking::Destinations::Snowplow, :event
      end

      context 'when destination is SnowplowMicro' do
        before do
          allow(Rails.env).to receive(:development?).and_return(true)
        end

        it_behaves_like 'rescued error raised by destination class' do
          let(:category) { 'category' }
          let(:action) { 'action' }
          let(:destination_class) { Gitlab::Tracking::Destinations::Snowplow }

          subject(:tracking_method) { described_class.event(category, action) }
        end

        it_behaves_like 'delegates to destination', Gitlab::Tracking::Destinations::SnowplowMicro, :event
      end
    end
  end

  describe 'snowplow_micro_enabled?' do
    where(:development?, :micro_verification_enabled?, :result) do
      true  | true  | true
      false | true  | true
      true  | false | true
      false | false | false
    end

    with_them do
      before do
        allow(Rails.env).to receive(:development?).and_return(development?)
        allow(described_class).to receive(:micro_verification_enabled?).and_return(micro_verification_enabled?)
      end

      subject { described_class.snowplow_micro_enabled? }

      it { is_expected.to be(result) }
    end
  end

  describe '.micro_verification_enabled?' do
    where(:verify_tracking, :result) do
      nil     | false
      'true'  | true
      'false' | false
      '0'     | false
      '1'     | true
    end

    with_them do
      before do
        stub_env('VERIFY_TRACKING', verify_tracking)
      end

      subject { described_class.micro_verification_enabled? }

      it { is_expected.to be(result) }
    end
  end

  describe 'tracker' do
    it 'returns a SnowPlowMicro instance in development' do
      allow(Rails.env).to receive(:development?).and_return(true)

      expect(described_class.tracker).to be_an_instance_of(Gitlab::Tracking::Destinations::SnowplowMicro)
    end

    it 'returns a SnowPlow instance when not in development' do
      allow(Rails.env).to receive(:development?).and_return(false)

      expect(described_class.tracker).to be_an_instance_of(Gitlab::Tracking::Destinations::Snowplow)
    end
  end
end
