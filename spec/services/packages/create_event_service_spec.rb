# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::CreateEventService do
  let(:scope) { 'container' }
  let(:event_name) { 'push_package' }

  let(:params) do
    {
      scope: scope,
      event_name: event_name
    }
  end

  subject { described_class.new(nil, user, params).execute }

  describe '#execute' do
    shared_examples 'db package event creation' do |originator_type, expected_scope|
      before do
        allow(::Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
      end

      context 'with feature flag disable' do
        before do
          stub_feature_flags(collect_package_events: false)
        end

        it 'does not create an event' do
          expect { subject }.not_to change { Packages::Event.count }
        end
      end

      context 'with feature flag enabled' do
        before do
          stub_feature_flags(collect_package_events: true)
        end

        it 'creates the event' do
          expect { subject }.to change { Packages::Event.count }.by(1)

          expect(subject.originator_type).to eq(originator_type)
          expect(subject.originator).to eq(user&.id)
          expect(subject.event_scope).to eq(expected_scope)
          expect(subject.event_type).to eq(event_name)
        end

        context 'on a read-only instance' do
          before do
            allow(Gitlab::Database).to receive(:read_only?).and_return(true)
          end

          it 'does not create an event' do
            expect { subject }.not_to change { Packages::Event.count }
          end
        end
      end
    end

    shared_examples 'redis package unique event creation' do |originator_type, expected_scope|
      it 'tracks the event' do
        expect(::Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(/package/, values: user.id)

        subject
      end
    end

    shared_examples 'redis package count event creation' do |originator_type, expected_scope|
      it 'tracks the event' do
        expect(::Gitlab::UsageDataCounters::PackageEventCounter).to receive(:count).at_least(:once)

        subject
      end
    end

    context 'with a user' do
      let(:user) { create(:user) }

      it_behaves_like 'db package event creation', 'user', 'container'
      it_behaves_like 'redis package unique event creation', 'user', 'container'
      it_behaves_like 'redis package count event creation', 'user', 'container'
    end

    context 'with a deploy token' do
      let(:user) { create(:deploy_token) }

      it_behaves_like 'db package event creation', 'deploy_token', 'container'
      it_behaves_like 'redis package unique event creation', 'deploy_token', 'container'
      it_behaves_like 'redis package count event creation', 'deploy_token', 'container'
    end

    context 'with no user' do
      let(:user) { nil }

      it_behaves_like 'db package event creation', 'guest', 'container'
      it_behaves_like 'redis package count event creation', 'guest', 'container'
    end

    context 'with a package as scope' do
      let(:scope) { create(:npm_package) }

      context 'as guest' do
        let(:user) { nil }

        it_behaves_like 'db package event creation', 'guest', 'npm'
        it_behaves_like 'redis package count event creation', 'guest', 'npm'
      end

      context 'with user' do
        let(:user) { create(:user) }

        it_behaves_like 'db package event creation', 'user', 'npm'
        it_behaves_like 'redis package unique event creation', 'user', 'npm'
        it_behaves_like 'redis package count event creation', 'user', 'npm'
      end
    end
  end
end
