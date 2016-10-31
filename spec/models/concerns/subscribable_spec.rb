require 'spec_helper'

describe Subscribable, 'Subscribable' do
  let(:project)  { create(:empty_project) }
  let(:resource) { create(:issue, project: project) }
  let(:user)     { create(:user) }

  describe '#subscribed?' do
    it 'returns false when no subcription exists' do
      expect(resource.subscribed?(user, project)).to be_falsey
    end

    it 'returns true when a subcription exists and subscribed is true' do
      resource.subscriptions.create(user: user, project: project, subscribed: true)

      expect(resource.subscribed?(user, project)).to be_truthy
    end

    it 'returns false when a subcription exists and subscribed is false' do
      resource.subscriptions.create(user: user, project: project, subscribed: false)

      expect(resource.subscribed?(user, project)).to be_falsey
    end
  end

  describe '#subscribers' do
    it 'returns [] when no subcribers exists' do
      expect(resource.subscribers(project)).to be_empty
    end

    it 'returns the subscribed users' do
      resource.subscriptions.create(user: user, project: project, subscribed: true)
      resource.subscriptions.create(user: create(:user), project: project, subscribed: false)

      expect(resource.subscribers(project)).to eq [user]
    end
  end

  describe '#toggle_subscription' do
    it 'toggles the current subscription state for the given user' do
      expect(resource.subscribed?(user, project)).to be_falsey

      resource.toggle_subscription(user, project)

      expect(resource.subscribed?(user, project)).to be_truthy
    end
  end

  describe '#subscribe' do
    it 'subscribes the given user' do
      expect(resource.subscribed?(user, project)).to be_falsey

      resource.subscribe(user, project)

      expect(resource.subscribed?(user, project)).to be_truthy
    end
  end

  describe '#unsubscribe' do
    it 'unsubscribes the given current user' do
      resource.subscriptions.create(user: user, project: project, subscribed: true)
      expect(resource.subscribed?(user, project)).to be_truthy

      resource.unsubscribe(user, project)

      expect(resource.subscribed?(user, project)).to be_falsey
    end
  end
end
