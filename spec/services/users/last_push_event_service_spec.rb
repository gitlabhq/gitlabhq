require 'spec_helper'

describe Users::LastPushEventService do
  let(:user) { build(:user, id: 1) }
  let(:project) { build(:project, id: 2) }
  let(:event) { build(:push_event, id: 3, author: user, project: project) }
  let(:service) { described_class.new(user) }

  describe '#cache_last_push_event' do
    it "caches the event for the event's project and current user" do
      expect(service).to receive(:set_key)
        .ordered
        .with('last-push-event/1/2', 3)

      expect(service).to receive(:set_key)
        .ordered
        .with('last-push-event/1', 3)

      service.cache_last_push_event(event)
    end

    it 'caches the event for the origin project when pushing to a fork' do
      source = build(:project, id: 5)

      allow(project).to receive(:forked_from_project).and_return(source)

      expect(service).to receive(:set_key)
        .ordered
        .with('last-push-event/1/2', 3)

      expect(service).to receive(:set_key)
        .ordered
        .with('last-push-event/1', 3)

      expect(service).to receive(:set_key)
        .ordered
        .with('last-push-event/1/5', 3)

      service.cache_last_push_event(event)
    end
  end

  describe '#last_event_for_user' do
    it 'returns the last push event for the current user' do
      expect(service).to receive(:find_cached_event)
        .with('last-push-event/1')
        .and_return(event)

      expect(service.last_event_for_user).to eq(event)
    end

    it 'returns nil when no push event could be found' do
      expect(service).to receive(:find_cached_event)
        .with('last-push-event/1')
        .and_return(nil)

      expect(service.last_event_for_user).to be_nil
    end
  end

  describe '#last_event_for_project' do
    it 'returns the last push event for the given project' do
      expect(service).to receive(:find_cached_event)
        .with('last-push-event/1/2')
        .and_return(event)

      expect(service.last_event_for_project(project)).to eq(event)
    end

    it 'returns nil when no push event could be found' do
      expect(service).to receive(:find_cached_event)
        .with('last-push-event/1/2')
        .and_return(nil)

      expect(service.last_event_for_project(project)).to be_nil
    end
  end

  describe '#find_cached_event', :use_clean_rails_memory_store_caching do
    context 'with a non-existing cache key' do
      it 'returns nil' do
        expect(service.find_cached_event('bla')).to be_nil
      end
    end

    context 'with an existing cache key' do
      before do
        service.cache_last_push_event(event)
      end

      it 'returns a PushEvent when no merge requests exist for the event' do
        allow(service).to receive(:find_event_in_database)
          .with(event.id)
          .and_return(event)

        expect(service.find_cached_event('last-push-event/1')).to eq(event)
      end

      it 'removes the cache key when no event could be found and returns nil' do
        allow(PushEvent).to receive(:without_existing_merge_requests)
          .and_return(PushEvent.none)

        expect(Rails.cache).to receive(:delete)
          .with('last-push-event/1')
          .and_call_original

        expect(service.find_cached_event('last-push-event/1')).to be_nil
      end
    end
  end
end
