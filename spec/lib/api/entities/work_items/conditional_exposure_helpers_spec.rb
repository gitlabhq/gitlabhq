# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::ConditionalExposureHelpers, feature_category: :team_planning do
  describe '.expose_field' do
    let(:callable_guard) do
      Class.new do
        attr_reader :calls

        def initialize
          @calls = 0
        end

        def call(_obj, options)
          @calls += 1
          options[:allow_callable_guard]
        end
      end.new
    end

    let(:entity_class) do
      guard = callable_guard

      Class.new(Grape::Entity) do
        include API::Entities::WorkItems::ConditionalExposureHelpers

        expose_field :optional
        expose_field :conditional, if: ->(_obj, options) { options[:allow] }
        expose_field :symbol_guard, if: :include_symbol
        expose_field :aliased_attr, as: :aliased
        expose_field :callable, if: guard
      end
    end

    let(:object) do
      Struct.new(:optional, :conditional, :symbol_guard, :aliased_attr, :callable)
        .new('foo', 'bar', 'baz', 'qux', 'quux')
    end

    it 'includes the field when it is requested' do
      representation = entity_class.represent(object, fields: [:optional]).as_json

      expect(representation).to include(optional: 'foo')
    end

    it 'supports string field requests' do
      representation = entity_class.represent(object, fields: ['optional']).as_json

      expect(representation).to include(optional: 'foo')
    end

    it 'omits the field when it is not requested' do
      representation = entity_class.represent(object, fields: []).as_json

      expect(representation).not_to have_key(:optional)
    end

    it 'omits the field when no field list is provided' do
      representation = entity_class.represent(object).as_json

      expect(representation).not_to have_key(:optional)
    end

    it 'combines additional guards with the request guard' do
      requested = entity_class.represent(object, fields: [:conditional], allow: true).as_json
      rejected = entity_class.represent(object, fields: [:conditional], allow: false).as_json

      expect(requested).to include(conditional: 'bar')
      expect(rejected).not_to have_key(:conditional)
    end

    it 'supports symbol :if guards' do
      allowed = entity_class.represent(object, fields: [:symbol_guard], include_symbol: true).as_json
      disallowed = entity_class.represent(object, fields: [:symbol_guard], include_symbol: false).as_json

      expect(allowed).to include(symbol_guard: 'baz')
      expect(disallowed).not_to have_key(:symbol_guard)
    end

    it 'uses the alias as the request key when provided' do
      representation = entity_class.represent(object, fields: [:aliased]).as_json

      expect(representation).to include(aliased: 'qux')
    end

    it 'supports callable guards responding to #call' do
      allowed = entity_class.represent(object, fields: [:callable], allow_callable_guard: true).as_json
      disallowed = entity_class.represent(object, fields: [:callable], allow_callable_guard: false).as_json

      expect(allowed).to include(callable: 'quux')
      expect(disallowed).not_to have_key(:callable)
      expect(callable_guard.calls).to eq(2)
    end
  end

  describe '.expose_feature' do
    context 'without widget guard' do
      let(:callable_guard) do
        Class.new do
          attr_reader :calls

          def initialize
            @calls = 0
          end

          def call(_obj, options)
            @calls += 1
            options[:allow_callable_feature]
          end
        end.new
      end

      let(:entity_class) do
        guard = callable_guard

        Class.new(Grape::Entity) do
          include API::Entities::WorkItems::ConditionalExposureHelpers

          expose_feature :widget, if: ->(obj, _options) { obj[:widget] }
          expose_feature :symbol_feature, if: :allow_symbol_feature
          expose_feature :callable_feature, if: guard
        end
      end

      let(:object) { { widget: { value: 1 }, symbol_feature: true, callable_feature: { value: 3 } } }

      it 'includes the feature when it is requested' do
        representation = entity_class.represent(object, requested_features: [:widget]).as_json

        expect(representation).to include(widget: { value: 1 })
      end

      it 'supports string feature requests' do
        representation = entity_class.represent(object, requested_features: ['widget']).as_json

        expect(representation).to include(widget: { value: 1 })
      end

      it 'omits the feature when it is not requested' do
        representation = entity_class.represent(object, requested_features: []).as_json

        expect(representation).not_to have_key(:widget)
      end

      it 'omits the feature when no feature list is provided' do
        representation = entity_class.represent(object).as_json

        expect(representation).not_to have_key(:widget)
      end

      it 'combines additional guards with the feature guard' do
        allowed = entity_class
          .represent(object, requested_features: [:symbol_feature], allow_symbol_feature: true)
          .as_json
        disallowed = entity_class
          .represent(object, requested_features: [:symbol_feature], allow_symbol_feature: false)
          .as_json

        expect(allowed).to include(symbol_feature: true)
        expect(disallowed).not_to have_key(:symbol_feature)
      end

      it 'supports callable guards responding to #call' do
        allowed = entity_class
          .represent(object, requested_features: [:callable_feature], allow_callable_feature: true)
          .as_json
        disallowed = entity_class
          .represent(object, requested_features: [:callable_feature], allow_callable_feature: false)
          .as_json

        expect(allowed).to include(callable_feature: { value: 3 })
        expect(disallowed).not_to have_key(:callable_feature)
        expect(callable_guard.calls).to eq(2)
      end
    end

    context 'with widget guard' do
      let(:entity_class) do
        Class.new(Grape::Entity) do
          include API::Entities::WorkItems::ConditionalExposureHelpers

          expose_feature :widget, widget_name: :widget do |widget|
            widget
          end

          expose_feature :custom_feature, widget_name: :custom_widget do |widget|
            widget
          end
        end
      end

      let(:work_item_class) do
        Class.new do
          def initialize(enabled_widgets:, data: {})
            @enabled_widgets = Array(enabled_widgets)
            @data = data
          end

          def [](key)
            @data[key]
          end

          def has_widget?(widget)
            @enabled_widgets.include?(widget)
          end

          def get_widget(widget)
            @data[widget]
          end
        end
      end

      let(:enabled_work_item) do
        work_item_class.new(
          enabled_widgets: %i[widget custom_widget],
          data: { widget: { value: 1 }, custom_widget: { value: 2 } }
        )
      end

      let(:disabled_work_item) do
        work_item_class.new(enabled_widgets: [], data: { widget: { value: 1 } })
      end

      it 'includes the feature when the widget is available' do
        representation = entity_class.represent(enabled_work_item, requested_features: [:widget]).as_json

        expect(representation).to include(widget: { value: 1 })
      end

      it 'omits the feature when the widget is unavailable' do
        representation = entity_class.represent(disabled_work_item, requested_features: [:widget]).as_json

        expect(representation).not_to have_key(:widget)
      end

      it 'supports custom widget names' do
        representation = entity_class.represent(enabled_work_item, requested_features: [:custom_feature]).as_json

        expect(representation).to include(custom_feature: { value: 2 })
      end

      it 'does not evaluate the widget guard when the feature is not requested' do
        work_item = Class.new(work_item_class) do
          attr_reader :has_widget_calls

          def initialize
            super(enabled_widgets: [:widget], data: { widget: { value: 1 } })
            @has_widget_calls = 0
          end

          def has_widget?(widget)
            @has_widget_calls += 1
            super
          end
        end.new

        entity_class.represent(work_item, requested_features: []).as_json

        expect(work_item.has_widget_calls).to eq(0)
      end

      it 'raises when the object does not support widget checks' do
        expect do
          entity_class.represent({ widget: { value: 1 } }, requested_features: [:widget]).as_json
        end.to raise_error(ArgumentError, 'Feature widget requires entity object to respond to :has_widget?')
      end

      it 'omits the feature when the widget lookup returns nil' do
        work_item = work_item_class.new(enabled_widgets: [:widget], data: { widget: nil })

        representation = entity_class.represent(work_item, requested_features: [:widget]).as_json

        expect(representation[:widget]).to be_nil
      end

      it 'raises when the object does not respond to #get_widget' do
        work_item = Class.new do
          def has_widget?(_widget)
            true
          end

          def [](_key)
            nil
          end
        end.new

        expect do
          entity_class.represent(work_item, requested_features: [:widget]).as_json
        end.to raise_error(ArgumentError, 'Feature widget requires entity object to respond to :get_widget')
      end
    end

    context 'with invalid widget name' do
      it 'raises an error when the widget name is not a symbol' do
        expect do
          Class.new(Grape::Entity) do
            include API::Entities::WorkItems::ConditionalExposureHelpers

            expose_feature :widget, widget_name: 'not_symbol'
          end
        end.to raise_error(ArgumentError, 'Unsupported :widget_name option "not_symbol" for feature widget')
      end
    end
  end

  describe '.options_with_guards' do
    let(:dummy_entity_class) do
      Class.new(Grape::Entity) do
        include API::Entities::WorkItems::ConditionalExposureHelpers
      end
    end

    it 'duplicates the options when no guards are provided' do
      options = { expose_nil: true }

      result = dummy_entity_class.send(:options_with_guards, options)

      expect(result).to eq(options)
      expect(result).not_to equal(options)
      expect(result).not_to have_key(:if)
    end

    it 'raises an error for unsupported guard types' do
      expect do
        dummy_entity_class.send(:normalize_guard, 123)
      end.to raise_error(ArgumentError, 'Unsupported condition 123')
    end
  end
end
