# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::CreateEventService, feature_category: :package_registry do
  let(:scope) { 'generic' }
  let(:event_name) { 'push_package' }

  let(:params) do
    {
      scope: scope,
      event_name: event_name
    }
  end

  subject { described_class.new(nil, user, params).execute }

  describe '#execute' do
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

      it_behaves_like 'redis package unique event creation', 'user', 'generic'
      it_behaves_like 'redis package count event creation', 'user', 'generic'
    end

    context 'with a deploy token' do
      let(:user) { create(:deploy_token) }

      it_behaves_like 'redis package unique event creation', 'deploy_token', 'generic'
      it_behaves_like 'redis package count event creation', 'deploy_token', 'generic'
    end

    context 'with no user' do
      let(:user) { nil }

      it_behaves_like 'redis package count event creation', 'guest', 'generic'
    end

    context 'with a package as scope' do
      let(:scope) { create(:npm_package) }

      context 'as guest' do
        let(:user) { nil }

        it_behaves_like 'redis package count event creation', 'guest', 'npm'
      end

      context 'with user' do
        let(:user) { create(:user) }

        it_behaves_like 'redis package unique event creation', 'user', 'npm'
        it_behaves_like 'redis package count event creation', 'user', 'npm'
      end
    end
  end
end
