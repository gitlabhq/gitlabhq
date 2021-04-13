# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscribable, 'Subscribable' do
  let(:project)  { create(:project) }
  let(:resource) { create(:issue, project: project) }
  let(:user_1)   { create(:user) }

  shared_examples 'returns expected values' do |method|
    context 'without user' do
      it 'returns false' do
        expect(resource.public_send(method, nil, project)).to be_falsey
      end
    end

    context 'without project' do
      it 'returns false when no subscription exists' do
        expect(resource.public_send(method, user_1)).to be_falsey
      end

      it 'returns true when a subscription exists and subscribed is true' do
        resource.subscriptions.create!(user: user_1, subscribed: true)

        expect(resource.public_send(method, user_1)).to be_truthy
      end

      it 'returns false when a subscription exists and subscribed is false' do
        resource.subscriptions.create!(user: user_1, subscribed: false)

        expect(resource.public_send(method, user_1)).to be_falsey
      end
    end

    context 'with project' do
      it 'returns false when no subscription exists' do
        expect(resource.public_send(method, user_1, project)).to be_falsey
      end

      it 'returns true when a subscription exists and subscribed is true' do
        resource.subscriptions.create!(user: user_1, project: project, subscribed: true)

        expect(resource.public_send(method, user_1, project)).to be_truthy
      end

      it 'returns false when a subscription exists and subscribed is false' do
        resource.subscriptions.create!(user: user_1, project: project, subscribed: false)

        expect(resource.public_send(method, user_1, project)).to be_falsey
      end
    end
  end

  describe '#subscribed?' do
    it_behaves_like 'returns expected values', :subscribed?
  end

  describe '#subscribers' do
    it 'returns [] when no subcribers exists' do
      expect(resource.subscribers(project)).to be_empty
    end

    it 'returns the subscribed users' do
      user_2 = create(:user)
      resource.subscriptions.create!(user: user_1, subscribed: true)
      resource.subscriptions.create!(user: user_2, project: project, subscribed: true)
      resource.subscriptions.create!(user: create(:user), project: project, subscribed: false)

      expect(resource.subscribers(project)).to contain_exactly(user_1, user_2)
    end
  end

  describe '#toggle_subscription' do
    context 'without project' do
      it 'toggles the current subscription state for the given user' do
        expect(resource.subscribed?(user_1)).to be_falsey

        resource.toggle_subscription(user_1)

        expect(resource.subscribed?(user_1)).to be_truthy
      end
    end

    context 'with project' do
      it 'toggles the current subscription state for the given user' do
        expect(resource.subscribed?(user_1, project)).to be_falsey

        resource.toggle_subscription(user_1, project)

        expect(resource.subscribed?(user_1, project)).to be_truthy
      end
    end
  end

  describe '#subscribe' do
    context 'without project' do
      it 'subscribes the given user' do
        expect(resource.subscribed?(user_1)).to be_falsey

        resource.subscribe(user_1)

        expect(resource.subscribed?(user_1)).to be_truthy
      end
    end

    context 'with project' do
      it 'subscribes the given user' do
        expect(resource.subscribed?(user_1, project)).to be_falsey

        resource.subscribe(user_1, project)

        expect(resource.subscribed?(user_1, project)).to be_truthy
      end
    end
  end

  describe '#unsubscribe' do
    context 'without project' do
      it 'unsubscribes the given current user' do
        resource.subscriptions.create!(user: user_1, subscribed: true)
        expect(resource.subscribed?(user_1)).to be_truthy

        resource.unsubscribe(user_1)

        expect(resource.subscribed?(user_1)).to be_falsey
      end
    end

    context 'with project' do
      it 'unsubscribes the given current user' do
        resource.subscriptions.create!(user: user_1, project: project, subscribed: true)
        expect(resource.subscribed?(user_1, project)).to be_truthy

        resource.unsubscribe(user_1, project)

        expect(resource.subscribed?(user_1, project)).to be_falsey
      end
    end
  end

  describe '#set_subscription' do
    shared_examples 'setting subscriptions' do
      context 'when desired_state is set to true' do
        context 'when a user is subscribed to the resource' do
          it 'keeps the user subscribed' do
            resource.subscriptions.create!(user: user_1, subscribed: true, project: resource_project)

            resource.set_subscription(user_1, true, resource_project)

            expect(resource.subscribed?(user_1, resource_project)).to be_truthy
          end
        end

        context 'when a user is not subscribed to the resource' do
          it 'subscribes the user to the resource' do
            expect { resource.set_subscription(user_1, true, resource_project) }
              .to change { resource.subscribed?(user_1, resource_project) }
              .from(false).to(true)
          end
        end
      end

      context 'when desired_state is set to false' do
        context 'when a user is subscribed to the resource' do
          it 'unsubscribes the user from the resource' do
            resource.subscriptions.create!(user: user_1, subscribed: true, project: resource_project)

            expect { resource.set_subscription(user_1, false, resource_project) }
              .to change { resource.subscribed?(user_1, resource_project) }
              .from(true).to(false)
          end
        end

        context 'when a user is not subscribed to the resource' do
          it 'keeps the user unsubscribed' do
            resource.set_subscription(user_1, false, resource_project)

            expect(resource.subscribed?(user_1, resource_project)).to be_falsey
          end
        end
      end
    end

    context 'without project' do
      let(:resource_project) { nil }

      it_behaves_like 'setting subscriptions'
    end

    context 'with project' do
      let(:resource_project) { project }

      it_behaves_like 'setting subscriptions'
    end
  end

  describe '#lazy_subscription' do
    let(:labels) { create_list(:group_label, 5) }

    before do
      labels.each do |label|
        create(:subscription, :group_label, user: user_1, subscribable: label)
      end
    end

    it 'executes only one SQL query' do
      lazy_queries = ActiveRecord::QueryRecorder.new do
        labels.each { |label| label.lazy_subscription(user_1) }
      end

      preloaded_queries = ActiveRecord::QueryRecorder.new do
        labels.each { |label| label.lazy_subscription(user_1)&.subscribed? }
      end

      expect(lazy_queries.count).to eq(0)
      expect(preloaded_queries.count).to eq(1)
    end
  end
end
