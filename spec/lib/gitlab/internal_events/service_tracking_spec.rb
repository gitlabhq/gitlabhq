# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::InternalEvents::ServiceTracking, feature_category: :product_analytics do
  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:namespace) { build_stubbed(:namespace) }

  # Helper to build a minimal service class that includes the concern.
  def build_service_class(&block)
    Class.new do
      include Gitlab::InternalEvents::ServiceTracking

      class_eval(&block) if block
    end
  end

  describe '.track_internal_event' do
    it 'registers the event configuration on the class' do
      klass = build_service_class do
        track_internal_event 'my_event', on: :success
      end

      expect(klass.tracked_events).to contain_exactly(
        hash_including(event_name: 'my_event', on: :success)
      )
    end

    it 'supports multiple events' do
      klass = build_service_class do
        track_internal_event 'event_a', on: :success
        track_internal_event 'event_b', on: :error
      end

      expect(klass.tracked_events.pluck(:event_name)).to eq(%w[event_a event_b])
    end
  end

  describe '.tracked_events' do
    it 'merges events from ancestors so subclasses inherit parent registrations' do
      parent = build_service_class do
        track_internal_event 'parent_event', on: :success
      end

      child = Class.new(parent) do
        track_internal_event 'child_event', on: :error
      end

      expect(parent.tracked_events.pluck(:event_name)).to eq(%w[parent_event])
      expect(child.tracked_events.pluck(:event_name)).to eq(%w[parent_event child_event])
    end
  end

  describe '#execute wrapping' do
    context 'with on: :success' do
      context 'when execute returns a successful ServiceResponse' do
        let(:service_class) do
          build_service_class do
            track_internal_event 'board_created', on: :success

            def execute
              ServiceResponse.success(payload: {})
            end
          end
        end

        it 'fires the event' do
          expect(Gitlab::InternalEvents).to receive(:track_event)
            .with('board_created', hash_including(user: nil, project: nil, namespace: nil))

          service_class.new.execute
        end
      end

      context 'when execute returns an error ServiceResponse' do
        let(:service_class) do
          build_service_class do
            track_internal_event 'board_created', on: :success

            def execute
              ServiceResponse.error(message: 'oops')
            end
          end
        end

        it 'does not fire the event' do
          expect(Gitlab::InternalEvents).not_to receive(:track_event)

          service_class.new.execute
        end
      end

      context 'when execute returns a persisted ActiveRecord-like object' do
        let(:service_class) do
          build_service_class do
            track_internal_event 'label_created', on: :success

            def execute
              obj = Object.new
              def obj.persisted? = true
              def obj.project = nil
              def obj.namespace = nil
              def obj.group = nil
              obj
            end
          end
        end

        it 'fires the event' do
          expect(Gitlab::InternalEvents).to receive(:track_event)
            .with('label_created', anything)

          service_class.new.execute
        end
      end

      context 'when execute returns a non-persisted ActiveRecord-like object' do
        let(:service_class) do
          build_service_class do
            track_internal_event 'label_created', on: :success

            def execute
              obj = Object.new
              def obj.persisted? = false
              obj
            end
          end
        end

        it 'does not fire the event' do
          expect(Gitlab::InternalEvents).not_to receive(:track_event)

          service_class.new.execute
        end
      end
    end

    context 'with on: :error' do
      let(:service_class) do
        build_service_class do
          track_internal_event 'board_creation_failed', on: :error

          def execute
            ServiceResponse.error(message: 'oops')
          end
        end
      end

      it 'fires the event on error' do
        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with('board_creation_failed', anything)

        service_class.new.execute
      end

      context 'when execute returns success' do
        let(:service_class) do
          build_service_class do
            track_internal_event 'board_creation_failed', on: :error

            def execute
              ServiceResponse.success(payload: {})
            end
          end
        end

        it 'does not fire the event' do
          expect(Gitlab::InternalEvents).not_to receive(:track_event)

          service_class.new.execute
        end
      end
    end

    context 'with on: :always' do
      let(:service_class) do
        build_service_class do
          track_internal_event 'something_happened', on: :always

          def execute
            ServiceResponse.error(message: 'oops')
          end
        end
      end

      it 'fires the event regardless of result' do
        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with('something_happened', anything)

        service_class.new.execute
      end
    end

    context 'with on: Proc' do
      let(:service_class) do
        build_service_class do
          track_internal_event 'custom_event', on: ->(result) { result.is_a?(String) && result == 'ok' }

          def execute
            'ok'
          end
        end
      end

      it 'fires the event when the proc returns truthy' do
        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with('custom_event', anything)

        service_class.new.execute
      end

      context 'when the proc returns falsy' do
        let(:service_class) do
          build_service_class do
            track_internal_event 'custom_event', on: ->(result) { result == 'not_ok' }

            def execute
              'ok'
            end
          end
        end

        it 'does not fire the event' do
          expect(Gitlab::InternalEvents).not_to receive(:track_event)

          service_class.new.execute
        end
      end
    end

    context 'with on: Symbol (method name)' do
      let(:service_class) do
        build_service_class do
          track_internal_event 'custom_event', on: :custom_check?

          def execute
            ServiceResponse.success(payload: {})
          end

          private

          def custom_check?
            true
          end
        end
      end

      it 'fires the event when the method returns truthy' do
        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with('custom_event', anything)

        service_class.new.execute
      end
    end

    context 'with conditions:' do
      context 'when condition is a Symbol' do
        let(:service_class) do
          build_service_class do
            track_internal_event 'label_created', on: :success, conditions: :not_template?

            def execute
              ServiceResponse.success(payload: {})
            end

            private

            def not_template?
              false
            end
          end
        end

        it 'does not fire the event when condition returns false' do
          expect(Gitlab::InternalEvents).not_to receive(:track_event)

          service_class.new.execute
        end
      end

      context 'when condition is a Proc' do
        let(:service_class) do
          build_service_class do
            track_internal_event 'label_created', on: :success, conditions: ->(svc) { svc.allowed? }

            def execute
              ServiceResponse.success(payload: {})
            end

            def allowed?
              true
            end
          end
        end

        it 'fires the event when the proc returns truthy' do
          expect(Gitlab::InternalEvents).to receive(:track_event)
            .with('label_created', anything)

          service_class.new.execute
        end
      end

      context 'when multiple conditions are provided' do
        let(:service_class) do
          build_service_class do
            track_internal_event 'label_created', on: :success, conditions: [:cond_a?, :cond_b?]

            def execute
              ServiceResponse.success(payload: {})
            end

            private

            def cond_a?
              true
            end

            def cond_b?
              false
            end
          end
        end

        it 'does not fire the event when any condition returns false' do
          expect(Gitlab::InternalEvents).not_to receive(:track_event)

          service_class.new.execute
        end
      end
    end

    context 'with additional_properties:' do
      context 'when additional_properties is a Hash' do
        let(:service_class) do
          build_service_class do
            track_internal_event 'integration_configured', on: :success,
              additional_properties: { label: 'static_label' }

            def execute
              ServiceResponse.success(payload: {})
            end
          end
        end

        it 'passes the hash to track_event' do
          expect(Gitlab::InternalEvents).to receive(:track_event)
            .with('integration_configured', hash_including(additional_properties: { label: 'static_label' }))

          service_class.new.execute
        end
      end

      context 'when additional_properties is a Proc' do
        let(:service_class) do
          build_service_class do
            track_internal_event 'integration_configured', on: :success,
              additional_properties: ->(result) { { label: result.payload[:type] } }

            def execute
              ServiceResponse.success(payload: { type: 'slack' })
            end
          end
        end

        it 'calls the proc with the result and passes the hash to track_event' do
          expect(Gitlab::InternalEvents).to receive(:track_event)
            .with('integration_configured', hash_including(additional_properties: { label: 'slack' }))

          service_class.new.execute
        end
      end
    end

    context 'with tracking_*_source overrides' do
      let(:service_class) do
        build_service_class do
          track_internal_event 'board_created', on: :success

          attr_reader :current_user, :project, :namespace

          def initialize(user, project, namespace)
            @current_user = user
            @project = project
            @namespace = namespace
          end

          def execute
            ServiceResponse.success(payload: {})
          end

          private

          def tracking_user_source
            current_user
          end

          def tracking_project_source(_result)
            project
          end

          def tracking_namespace_source(_result)
            namespace
          end
        end
      end

      it 'uses the overridden source methods' do
        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with('board_created', hash_including(user: user, project: project, namespace: namespace))

        service_class.new(user, project, namespace).execute
      end
    end

    context 'with smart default tracking_user_source' do
      let(:service_class) do
        build_service_class do
          track_internal_event 'board_created', on: :success

          attr_reader :current_user

          def initialize(user)
            @current_user = user
          end

          def execute
            ServiceResponse.success(payload: {})
          end
        end
      end

      it 'defaults to current_user' do
        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with('board_created', hash_including(user: user))

        service_class.new(user).execute
      end
    end

    context 'with default tracking sources from ServiceResponse hash payload' do
      let(:board) { instance_double(Board, project: 'the_project', group: 'the_group') }
      let(:service_class) do
        klass = build_service_class do
          track_internal_event 'board_created', on: :success

          attr_accessor :board

          def execute
            ServiceResponse.success(payload: { board: board })
          end
        end
        klass
      end

      it 'extracts project and namespace from hash payload values' do
        svc = service_class.new
        svc.board = board

        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with('board_created', hash_including(project: 'the_project', namespace: 'the_group'))

        svc.execute
      end
    end

    context 'with default tracking sources from a plain ActiveRecord-like result' do
      let(:label) do
        instance_double(Label, project: 'the_project', group: 'the_group', persisted?: true)
      end

      let(:service_class) do
        klass = build_service_class do
          track_internal_event 'label_created', on: :success

          attr_accessor :label

          def execute
            label
          end
        end
        klass
      end

      it 'extracts project and namespace directly from the result' do
        svc = service_class.new
        svc.label = label

        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with('label_created', hash_including(project: 'the_project', namespace: 'the_group'))

        svc.execute
      end
    end

    context 'with multiple tracked events' do
      let(:service_class) do
        build_service_class do
          track_internal_event 'thing_created', on: :success
          track_internal_event 'thing_creation_failed', on: :error

          def execute
            ServiceResponse.success(payload: {})
          end
        end
      end

      it 'fires only the matching event' do
        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with('thing_created', anything).once
        expect(Gitlab::InternalEvents).not_to receive(:track_event)
          .with('thing_creation_failed', anything)

        service_class.new.execute
      end
    end

    context 'when execute accepts arguments' do
      let(:service_class) do
        build_service_class do
          track_internal_event 'label_created', on: :success

          def execute(target_params)
            ServiceResponse.success(payload: target_params)
          end
        end
      end

      it 'passes arguments through to the original execute' do
        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with('label_created', anything)

        result = service_class.new.execute({ project: 'something' })
        expect(result).to be_success
      end
    end

    context 'with an unrecognized on: option' do
      let(:service_class) do
        build_service_class do
          track_internal_event 'evt', on: 'unrecognized'

          def execute
            ServiceResponse.success(payload: {})
          end
        end
      end

      it 'raises ArgumentError in development/test and does not fire the event' do
        expect(Gitlab::InternalEvents).not_to receive(:track_event)

        expect { service_class.new.execute }.to raise_error(ArgumentError, /Invalid `on:` value/)
      end
    end

    context 'when execute returns a plain truthy value' do
      let(:service_class) do
        build_service_class do
          track_internal_event 'evt', on: :success

          def execute
            'a plain string result'
          end
        end
      end

      it 'fires the event using present? for success detection' do
        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with('evt', anything)

        service_class.new.execute
      end
    end

    context 'when execute returns a plain falsy value' do
      let(:service_class) do
        build_service_class do
          track_internal_event 'evt', on: :success

          def execute
            ''
          end
        end
      end

      it 'does not fire the event' do
        expect(Gitlab::InternalEvents).not_to receive(:track_event)

        service_class.new.execute
      end
    end

    context 'with an unrecognized condition entry' do
      let(:service_class) do
        build_service_class do
          track_internal_event 'evt', on: :success, conditions: 'unrecognized'

          def execute
            ServiceResponse.success(payload: {})
          end
        end
      end

      it 'raises ArgumentError in development/test and does not fire the event' do
        expect(Gitlab::InternalEvents).not_to receive(:track_event)

        expect { service_class.new.execute }.to raise_error(ArgumentError, /Invalid `conditions:` entry/)
      end
    end

    context 'with an unrecognized additional_properties value' do
      let(:service_class) do
        build_service_class do
          track_internal_event 'evt', on: :success, additional_properties: 'unrecognized'

          def execute
            ServiceResponse.success(payload: {})
          end
        end
      end

      it 'falls back to an empty hash' do
        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with('evt', hash_including(additional_properties: {}))

        service_class.new.execute
      end
    end

    context 'when ServiceResponse payload is not a Hash' do
      let(:service_class) do
        build_service_class do
          track_internal_event 'evt', on: :success

          def execute
            ServiceResponse.success(payload: 'not a hash')
          end
        end
      end

      it 'fires the event with nil project and namespace' do
        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with('evt', hash_including(project: nil, namespace: nil))

        service_class.new.execute
      end
    end
  end
end
