# frozen_string_literal: true

module SnowplowHelpers
  # Asserts call for one snowplow event from `Gitlab::Tracking#event`.
  #
  # @param [Hash]
  #
  # Examples:
  #
  #   describe '#show' do
  #     it 'tracks snowplow events' do
  #       get :show
  #
  #       expect_snowplow_event(category: 'Experiment', action: 'start')
  #     end
  #   end
  #
  #   describe '#create' do
  #     it 'tracks snowplow events' do
  #       post :create
  #
  #       expect_snowplow_event(
  #         category: 'Experiment',
  #         action: 'created',
  #       )
  #       expect_snowplow_event(
  #         category: 'Experiment',
  #         action: 'accepted',
  #         property: 'property',
  #         label: 'label'
  #       )
  #     end
  #   end
  #
  # Passing context:
  #
  #   Simply provide a hash that has the schema and data expected.
  #
  #   expect_snowplow_event(
  #     category: 'Experiment',
  #     action: 'created',
  #     context: [
  #       {
  #         schema: 'iglu:com.gitlab/.../0-3-0',
  #         data: { key: 'value' }
  #       }
  #     ]
  #   )
  def expect_snowplow_event(category:, action:, context: nil, tracking_method: :event, **kwargs)
    if context
      if context.is_a?(Array)
        kwargs[:context] = []
        context.each do |c|
          expect(SnowplowTracker::SelfDescribingJson).to have_received(:new)
            .with(c[:schema], c[:data]).at_least(:once)
          kwargs[:context] << an_instance_of(SnowplowTracker::SelfDescribingJson)
        end
      else
        kwargs[:context] = context
      end
    end

    expect(Gitlab::Tracking).to have_received(tracking_method)
      .with(category, action, **kwargs).at_least(:once)
  end

  def match_snowplow_context_schema(schema_path:, context:)
    expect(context).to match_snowplow_schema(schema_path)
  end

  # Asserts that no call to `Gitlab::Tracking#event` was made.
  #
  # Example:
  #
  #   describe '#show', :snowplow do
  #     it 'does not track any snowplow events' do
  #       get :show
  #
  #       expect_no_snowplow_event
  #     end
  #   end
  def expect_no_snowplow_event(category: nil, action: nil, tracking_method: :event, **kwargs)
    if category && action
      expect(Gitlab::Tracking).not_to have_received(tracking_method).with(category, action, **kwargs)
    else
      expect(Gitlab::Tracking).not_to have_received(tracking_method)
    end
  end
end
