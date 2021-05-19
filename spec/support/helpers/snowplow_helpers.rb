# frozen_string_literal: true

module SnowplowHelpers
  # Asserts call for one snowplow event from `Gitlab::Tracking#event`.
  #
  # @param [Hash]
  #
  # Examples:
  #
  #   describe '#show', :snowplow do
  #     it 'tracks snowplow events' do
  #       get :show
  #
  #       expect_snowplow_event(category: 'Experiment', action: 'start')
  #     end
  #   end
  #
  #   describe '#create', :snowplow do
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
  def expect_snowplow_event(category:, action:, context: nil, **kwargs)
    if context
      kwargs[:context] = []
      context.each do |c|
        expect(SnowplowTracker::SelfDescribingJson).to have_received(:new)
          .with(c[:schema], c[:data]).at_least(:once)
        kwargs[:context] << an_instance_of(SnowplowTracker::SelfDescribingJson)
      end
    end

    expect(Gitlab::Tracking).to have_received(:event) # rubocop:disable RSpec/ExpectGitlabTracking
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
  def expect_no_snowplow_event(category: nil, action: nil, **kwargs)
    if category && action
      expect(Gitlab::Tracking).not_to have_received(:event).with(category, action, **kwargs) # rubocop:disable RSpec/ExpectGitlabTracking
    else
      expect(Gitlab::Tracking).not_to have_received(:event) # rubocop:disable RSpec/ExpectGitlabTracking
    end
  end
end
