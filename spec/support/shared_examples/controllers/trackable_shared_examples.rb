# frozen_string_literal: true

RSpec.shared_examples 'a Trackable Controller' do
  describe '#track_event', :snowplow do
    before do
      sign_in user
    end

    context 'with no params' do
      controller(described_class) do
        def index
          track_event
          head :ok
        end
      end

      it 'tracks the action name', :snowplow do
        get :index

        expect_snowplow_event(category: 'AnonymousController', action: 'index')
      end
    end

    context 'with params' do
      controller(described_class) do
        def index
          track_event('some_event', category: 'SomeCategory', label: 'errorlabel')
          head :ok
        end
      end

      it 'tracks with the specified param' do
        get :index

        expect_snowplow_event(category: 'SomeCategory', action: 'some_event', label: 'errorlabel')
      end
    end
  end
end
