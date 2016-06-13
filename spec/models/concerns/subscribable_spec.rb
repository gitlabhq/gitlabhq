require 'spec_helper'

describe Subscribable, 'Subscribable' do
  let(:resource) { create(:issue) }
  let(:user) { create(:user) }

  describe '#subscribed?' do
    it 'returns false when no subcription exists' do
      expect(resource.subscribed?(user)).to be_falsey
    end

    it 'returns true when a subcription exists and subscribed is true' do
      resource.subscriptions.create(user: user, subscribed: true)

      expect(resource.subscribed?(user)).to be_truthy
    end

    it 'returns false when a subcription exists and subscribed is false' do
      resource.subscriptions.create(user: user, subscribed: false)

      expect(resource.subscribed?(user)).to be_falsey
    end
  end
  describe '#subscribers' do
    it 'returns [] when no subcribers exists' do
      expect(resource.subscribers).to be_empty
    end

    it 'returns the subscribed users' do
      resource.subscriptions.create(user: user, subscribed: true)
      resource.subscriptions.create(user: create(:user), subscribed: false)

      expect(resource.subscribers).to eq [user]
    end
  end

  describe '#toggle_subscription' do
    it 'toggles the current subscription state for the given user' do
      expect(resource.subscribed?(user)).to be_falsey

      resource.toggle_subscription(user)

      expect(resource.subscribed?(user)).to be_truthy
    end
  end

  describe '#subscribe' do
    it 'subscribes the given user' do
      expect(resource.subscribed?(user)).to be_falsey

      resource.subscribe(user)

      expect(resource.subscribed?(user)).to be_truthy
    end
  end

  describe '#unsubscribe' do
    it 'unsubscribes the given current user' do
      resource.subscriptions.create(user: user, subscribed: true)
      expect(resource.subscribed?(user)).to be_truthy

      resource.unsubscribe(user)

      expect(resource.subscribed?(user)).to be_falsey
    end
  end
end
