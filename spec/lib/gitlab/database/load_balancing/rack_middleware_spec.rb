require 'spec_helper'

describe Gitlab::Database::LoadBalancing::RackMiddleware, :redis do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }

  after do
    Gitlab::Database::LoadBalancing::Session.clear_session
  end

  describe '.stick_or_unstick' do
    it 'sticks or unsticks and updates the Rack environment' do
      allow(Gitlab::Database::LoadBalancing).to receive(:enable?)
        .and_return(true)

      expect(Gitlab::Database::LoadBalancing::Sticking)
        .to receive(:unstick_or_continue_sticking)
        .with(:user, 42)

      env = {}

      described_class.stick_or_unstick(env, :user, 42)

      expect(env[described_class::STICK_OBJECT]).to eq([:user, 42])
    end
  end

  describe '#call' do
    it 'handles a request' do
      env = {}

      expect(middleware).to receive(:clear).twice

      expect(middleware).to receive(:unstick_or_continue_sticking).with(env)
      expect(middleware).to receive(:stick_if_necessary).with(env)

      expect(app).to receive(:call).with(env).and_return(10)

      expect(middleware.call(env)).to eq(10)
    end
  end

  describe '#unstick_or_continue_sticking' do
    it 'does not stick if no namespace and identifier could be found' do
      expect(Gitlab::Database::LoadBalancing::Sticking)
        .not_to receive(:unstick_or_continue_sticking)

      middleware.unstick_or_continue_sticking({})
    end

    it 'sticks to the primary if a sticking namespace and identifier were found' do
      env = { described_class::STICK_OBJECT => [:user, 42] }

      expect(Gitlab::Database::LoadBalancing::Sticking)
        .to receive(:unstick_or_continue_sticking)
        .with(:user, 42)

      middleware.unstick_or_continue_sticking(env)
    end
  end

  describe '#stick_if_necessary' do
    it 'does not stick to the primary if not necessary' do
      expect(Gitlab::Database::LoadBalancing::Sticking)
        .not_to receive(:stick_if_necessary)

      middleware.stick_if_necessary({})
    end

    it 'sticks to the primary if necessary' do
      env = { described_class::STICK_OBJECT => [:user, 42] }

      expect(Gitlab::Database::LoadBalancing::Sticking)
        .to receive(:stick_if_necessary)
        .with(:user, 42)

      middleware.stick_if_necessary(env)
    end
  end

  describe '#clear' do
    it 'clears the currently used host and session' do
      lb = double(:lb)
      session = double(:session)

      allow(middleware).to receive(:load_balancer).and_return(lb)

      expect(lb).to receive(:release_host)

      stub_const('Gitlab::Database::LoadBalancing::RackMiddleware::Session',
                 session)

      expect(session).to receive(:clear_session)

      middleware.clear
    end
  end

  describe '.load_balancer' do
    it 'returns a the load balancer' do
      proxy = double(:proxy)

      expect(Gitlab::Database::LoadBalancing).to receive(:proxy)
        .and_return(proxy)

      expect(proxy).to receive(:load_balancer)

      middleware.load_balancer
    end
  end

  describe '#sticking_namespace_and_id' do
    context 'using a Warden request' do
      it 'returns the warden user if present' do
        user = double(:user, id: 42)
        warden = double(:warden, user: user)
        env = { 'warden' => warden }

        expect(middleware.sticking_namespace_and_id(env)).to eq([:user, 42])
      end

      it 'returns an empty Array if no user was present' do
        warden = double(:warden, user: nil)
        env = { 'warden' => warden }

        expect(middleware.sticking_namespace_and_id(env)).to eq([])
      end
    end

    context 'using a request with a manually set sticking object' do
      it 'returns the sticking object' do
        env = { described_class::STICK_OBJECT => [:user, 42] }

        expect(middleware.sticking_namespace_and_id(env)).to eq([:user, 42])
      end
    end

    context 'using a regular request' do
      it 'returns an empty Array' do
        expect(middleware.sticking_namespace_and_id({})).to eq([])
      end
    end
  end
end
