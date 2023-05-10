# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Tracking, feature_category: :application_instrumentation do
  include StubENV

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
                .with(project_id: project.id, user_id: user.id, namespace_id: namespace.id, plan_name: namespace.actual_plan_name, extra_key_1: 'extra value 1', extra_key_2: 'extra value 2')
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

    describe '.database_event' do
      context 'when the action is not passed in as a string' do
        it 'allows symbols' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

          described_class.database_event('category', :some_action)
        end

        it 'allows nil' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

          described_class.database_event('category', nil)
        end

        it 'allows integers' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

          described_class.database_event('category', 1)
        end
      end

      it_behaves_like 'rescued error raised by destination class' do
        let(:category) { 'Issue' }
        let(:action) { 'created' }
        let(:destination_class) { Gitlab::Tracking::Destinations::DatabaseEventsSnowplow }

        subject(:tracking_method) { described_class.database_event(category, action) }
      end

      it_behaves_like 'delegates to destination', Gitlab::Tracking::Destinations::DatabaseEventsSnowplow, :database_event
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

  describe '.definition' do
    let(:namespace) { create(:namespace) }

    let_it_be(:definition_action) { 'definition_action' }
    let_it_be(:definition_category) { 'definition_category' }
    let_it_be(:label_description) { 'definition label description' }
    let_it_be(:test_definition) { { 'category': definition_category, 'action': definition_action } }

    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:event)
      end
      allow_next_instance_of(Gitlab::Tracking::Destinations::Snowplow) do |instance|
        allow(instance).to receive(:event)
      end
      allow(YAML).to receive(:load_file).with(Rails.root.join('config/events/filename.yml')).and_return(test_definition)
    end

    it 'dispatchs the data to .event' do
      project = build_stubbed(:project)
      user = build_stubbed(:user)

      expect(described_class).to receive(:event) do |category, action, args|
        expect(category).to eq(definition_category)
        expect(action).to eq(definition_action)
        expect(args[:label]).to eq('label')
        expect(args[:property]).to eq('...')
        expect(args[:project]).to eq(project)
        expect(args[:user]).to eq(user)
        expect(args[:namespace]).to eq(namespace)
        expect(args[:extra_key_1]).to eq('extra value 1')
      end

      described_class.definition('filename',
        category: nil,
        action: nil,
        label: 'label',
        property: '...',
        project: project,
        user: user,
        namespace: namespace,
        extra_key_1: 'extra value 1')
    end
  end

  describe 'snowplow_micro_enabled?' do
    before do
      allow(Rails.env).to receive(:development?).and_return(true)
    end

    it 'returns true when snowplow_micro is enabled' do
      stub_config(snowplow_micro: { enabled: true })

      expect(described_class).to be_snowplow_micro_enabled
    end

    it 'returns false when snowplow_micro is disabled' do
      stub_config(snowplow_micro: { enabled: false })

      expect(described_class).not_to be_snowplow_micro_enabled
    end

    it 'returns false when snowplow_micro is not configured' do
      allow(Gitlab.config).to receive(:snowplow_micro).and_raise(GitlabSettings::MissingSetting)

      expect(described_class).not_to be_snowplow_micro_enabled
    end
  end
end
