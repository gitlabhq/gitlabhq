# frozen_string_literal: true

RSpec.shared_examples 'a Trackable Controller' do
  describe '#track_event' do
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

      it 'tracks the action name' do
        expect(Gitlab::Tracking).to receive(:event).with('AnonymousController', 'index', {})
        get :index
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
        expect(Gitlab::Tracking).to receive(:event).with('SomeCategory', 'some_event', label: 'errorlabel')
        get :index
      end
    end
  end
end
