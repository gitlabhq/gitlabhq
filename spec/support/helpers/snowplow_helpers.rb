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
    # This check will no longer be needed with Ruby 2.7 which
    # would not pass any arguments when using **kwargs.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/263430
    if kwargs.present?
      expect(Gitlab::Tracking).to have_received(:event)
        .with(category, action, **kwargs).at_least(:once)
    else
      expect(Gitlab::Tracking).to have_received(:event)
        .with(category, action).at_least(:once)
    end
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
    expect(Gitlab::Tracking).not_to have_received(:event)
  end
end
