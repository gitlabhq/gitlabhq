# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::RackMiddleware, :redis do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:warden_user) { double(:warden, user: double(:user, id: 42)) }
  let(:single_sticking_object) { Set.new([[ActiveRecord::Base.sticking, :user, 42]]) }
  let(:multiple_sticking_objects) do
    Set.new([
              [ActiveRecord::Base.sticking, :user, 42],
              [ActiveRecord::Base.sticking, :runner, '123456789'],
              [ActiveRecord::Base.sticking, :runner, '1234']
            ])
  end

  after do
    Gitlab::Database::LoadBalancing::Session.clear_session
  end

  describe '#call' do
    it 'handles a request' do
      env = {}

      expect(middleware).to receive(:clear).twice

      expect(middleware).to receive(:unstick_or_continue_sticking).with(env)
      expect(middleware).to receive(:stick_if_necessary).with(env)

      expect(app).to receive(:call).with(env).and_return(10)

      allow(ActiveSupport::Notifications).to receive(:instrument).and_call_original

      expect(ActiveSupport::Notifications)
        .to receive(:instrument)
        .with('web_transaction_completed.load_balancing')
        .and_call_original

      expect(middleware.call(env)).to eq(10)
    end
  end

  describe '#unstick_or_continue_sticking' do
    it 'does not stick if no namespace and identifier could be found' do
      expect(ApplicationRecord.sticking)
        .not_to receive(:unstick_or_continue_sticking)

      middleware.unstick_or_continue_sticking({})
    end

    it 'sticks to the primary if a warden user is found' do
      env = { 'warden' => warden_user }

      Gitlab::Database::LoadBalancing.base_models.each do |model|
        expect(model.sticking)
          .to receive(:unstick_or_continue_sticking)
          .with(:user, 42)
      end

      middleware.unstick_or_continue_sticking(env)
    end

    it 'sticks to the primary if a sticking namespace and identifier is found' do
      env = { described_class::STICK_OBJECT => single_sticking_object }

      expect(ApplicationRecord.sticking)
        .to receive(:unstick_or_continue_sticking)
        .with(:user, 42)

      middleware.unstick_or_continue_sticking(env)
    end

    it 'sticks to the primary if multiple sticking namespaces and identifiers were found' do
      env = { described_class::STICK_OBJECT => multiple_sticking_objects }

      expect(ApplicationRecord.sticking)
        .to receive(:unstick_or_continue_sticking)
        .with(:user, 42)
        .ordered

      expect(ApplicationRecord.sticking)
        .to receive(:unstick_or_continue_sticking)
        .with(:runner, '123456789')
        .ordered

      expect(ApplicationRecord.sticking)
        .to receive(:unstick_or_continue_sticking)
        .with(:runner, '1234')
        .ordered

      middleware.unstick_or_continue_sticking(env)
    end
  end

  describe '#stick_if_necessary' do
    it 'does not stick to the primary if not necessary' do
      expect(ApplicationRecord.sticking)
        .not_to receive(:stick_if_necessary)

      middleware.stick_if_necessary({})
    end

    it 'sticks to the primary if a warden user is found' do
      env = { 'warden' => warden_user }

      Gitlab::Database::LoadBalancing.base_models.each do |model|
        expect(model.sticking)
          .to receive(:stick_if_necessary)
          .with(:user, 42)
      end

      middleware.stick_if_necessary(env)
    end

    it 'sticks to the primary if a a single sticking object is found' do
      env = { described_class::STICK_OBJECT => single_sticking_object }

      expect(ApplicationRecord.sticking)
        .to receive(:stick_if_necessary)
        .with(:user, 42)

      middleware.stick_if_necessary(env)
    end

    it 'sticks to the primary if multiple sticking namespaces and identifiers were found' do
      env = { described_class::STICK_OBJECT => multiple_sticking_objects }

      expect(ApplicationRecord.sticking)
        .to receive(:stick_if_necessary)
        .with(:user, 42)
        .ordered

      expect(ApplicationRecord.sticking)
        .to receive(:stick_if_necessary)
        .with(:runner, '123456789')
        .ordered

      expect(ApplicationRecord.sticking)
        .to receive(:stick_if_necessary)
        .with(:runner, '1234')
        .ordered

      middleware.stick_if_necessary(env)
    end
  end

  describe '#clear' do
    it 'clears the currently used host and session' do
      session = spy(:session)

      stub_const('Gitlab::Database::LoadBalancing::Session', session)

      expect(Gitlab::Database::LoadBalancing).to receive(:release_hosts)

      middleware.clear

      expect(session).to have_received(:clear_session)
    end
  end

  describe '#sticking_namespaces' do
    context 'using a Warden request' do
      it 'returns the warden user if present' do
        env = { 'warden' => warden_user }
        ids = Gitlab::Database::LoadBalancing.base_models.map do |model|
          [model.sticking, :user, 42]
        end

        expect(middleware.sticking_namespaces(env)).to eq(ids)
      end

      it 'returns an empty Array if no user was present' do
        warden = double(:warden, user: nil)
        env = { 'warden' => warden }

        expect(middleware.sticking_namespaces(env)).to eq([])
      end
    end

    context 'using a request with a manually set sticking object' do
      it 'returns the sticking object' do
        env = { described_class::STICK_OBJECT => multiple_sticking_objects }

        expect(middleware.sticking_namespaces(env)).to eq(
          [
            [ActiveRecord::Base.sticking, :user, 42],
            [ActiveRecord::Base.sticking, :runner, '123456789'],
            [ActiveRecord::Base.sticking, :runner, '1234']
          ])
      end
    end

    context 'using a regular request' do
      it 'returns an empty Array' do
        expect(middleware.sticking_namespaces({})).to eq([])
      end
    end
  end
end
