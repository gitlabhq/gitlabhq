# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::RackMiddleware, :redis do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:warden_user) { double(:warden, user: double(:user, id: 42)) }
  let(:single_sticking_object) { Set.new([[ActiveRecord::Base.sticking, :user, 99]]) }
  let(:multiple_sticking_objects) do
    Set.new([
      [ActiveRecord::Base.sticking, :user, 42],
              [ActiveRecord::Base.sticking, :runner, '123456789'],
              [ActiveRecord::Base.sticking, :runner, '1234']
    ])
  end

  after do
    Gitlab::Database::LoadBalancing::SessionMap.clear_session
  end

  describe '#call' do
    it 'handles a request' do
      env = {}

      expect(middleware).to receive(:clear).twice

      expect(middleware).to receive(:find_caught_up_replica).with(env)
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

  describe '#find_caught_up_replica' do
    it 'does not stick if no namespace and identifier could be found' do
      expect(ApplicationRecord.sticking)
        .not_to receive(:find_caught_up_replica)

      middleware.find_caught_up_replica({})
    end

    it 'sticks to the primary if a warden user is found' do
      env = { 'warden' => warden_user }

      Gitlab::Database::LoadBalancing.base_models.each do |model|
        expect(model.sticking)
          .to receive(:find_caught_up_replica)
          .with(:user, 42)
      end

      middleware.find_caught_up_replica(env)
    end

    it 'sticks to the primary if a sticking namespace and identifier is found' do
      env = { described_class::STICK_OBJECT => single_sticking_object }

      expect(ApplicationRecord.sticking)
        .to receive(:find_caught_up_replica)
        .with(:user, 99)

      middleware.find_caught_up_replica(env)
    end

    it 'sticks to the primary if multiple sticking namespaces and identifiers were found' do
      env = { described_class::STICK_OBJECT => multiple_sticking_objects }

      expect(ApplicationRecord.sticking)
        .to receive(:find_caught_up_replica)
        .with(:user, 42)
        .ordered

      expect(ApplicationRecord.sticking)
        .to receive(:find_caught_up_replica)
        .with(:runner, '123456789')
        .ordered

      expect(ApplicationRecord.sticking)
        .to receive(:find_caught_up_replica)
        .with(:runner, '1234')
        .ordered

      middleware.find_caught_up_replica(env)
    end
  end

  describe '#stick_if_necessary' do
    let(:env) { { 'warden' => warden, described_class::STICK_OBJECT => stick_object }.compact }
    let(:stick_object) { nil }
    let(:write_performed) { true }
    let(:warden) { warden_user }

    before do
      Gitlab::Database::LoadBalancing.base_models.each do |model|
        allow(::Gitlab::Database::LoadBalancing::SessionMap.current(model.load_balancer))
          .to receive(:performed_write?)
          .and_return(write_performed)
      end
    end

    subject { middleware.stick_if_necessary(env) }

    it 'sticks to the primary for the user' do
      Gitlab::Database::LoadBalancing.base_models.each do |model|
        expect(model.sticking)
          .to receive(:stick)
          .with(:user, 42)
      end

      subject
    end

    context 'when no write was performed' do
      let(:write_performed) { false }

      it 'does not stick to the primary' do
        expect(ApplicationRecord.sticking)
          .not_to receive(:stick)

        subject
      end
    end

    context 'when there is no user in the env' do
      let(:warden) { nil }

      context 'when there is an explicit single sticking object in the env' do
        let(:stick_object) { single_sticking_object }

        it 'sticks to the single sticking object' do
          expect(ApplicationRecord.sticking)
            .to receive(:stick)
            .with(:user, 99)

          subject
        end
      end

      context 'when there is multiple explicit sticking objects' do
        let(:stick_object) { multiple_sticking_objects }

        it 'sticks to the sticking objects' do
          expect(ApplicationRecord.sticking)
            .to receive(:stick)
            .with(:user, 42)
            .ordered

          expect(ApplicationRecord.sticking)
            .to receive(:stick)
            .with(:runner, '123456789')
            .ordered

          expect(ApplicationRecord.sticking)
            .to receive(:stick)
            .with(:runner, '1234')
            .ordered

          subject
        end
      end

      context 'when there no explicit sticking objects' do
        it 'does not stick to the primary' do
          expect(ApplicationRecord.sticking)
            .not_to receive(:stick)

          subject
        end
      end
    end
  end

  describe '#clear' do
    it 'clears the currently used host and session' do
      session = spy(:session)

      stub_const('Gitlab::Database::LoadBalancing::SessionMap', session)

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
