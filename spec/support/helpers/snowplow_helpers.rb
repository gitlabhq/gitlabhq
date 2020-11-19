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
  def expect_snowplow_event(category:, action:, **kwargs)
    expect(Gitlab::Tracking).to have_received(:event) # rubocop:disable RSpec/ExpectGitlabTracking
      .with(category, action, **kwargs).at_least(:once)
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
  def expect_no_snowplow_event
    expect(Gitlab::Tracking).not_to have_received(:event) # rubocop:disable RSpec/ExpectGitlabTracking
  end
end
