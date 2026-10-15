# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::RackMiddleware, :redis, feature_category: :database do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:warden_user) { double(:warden, user: double(:user, id: 42)) }
  let(:warden_user_no_preload) { double(:warden) }
  let(:single_sticking_object) { Set.new([[ActiveRecord::Base.sticking, :user, 99]]) }
  let(:multiple_sticking_objects) do
    Set.new([
      [ActiveRecord::Base.sticking, :user, 42],
      [ActiveRecord::Base.sticking, :runner, '123456789'],
      [ActiveRecord::Base.sticking, :runner, '1234']
    ])
  end

  before do
    stub_feature_flags(grab_user_id_from_warden_session: false)
  end

  after do
    Gitlab::Database::LoadBalancing::SessionMap.clear_session
  end

  describe '#call' do
    it 'handles a request' do
      env = {}

      expect(middleware).to receive(:clear).twice

      expect(middleware).to receive(:add_path_stick_objects).with(env).ordered
      expect(middleware).to receive(:find_caught_up_replica).with(env).ordered
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

  describe '#add_path_stick_objects' do
    let(:build_sticking) { ::Ci::Build.sticking }

    def stick_objects_for(path, env = {})
      env = Rack::MockRequest.env_for(path).merge(env)
      middleware.add_path_stick_objects(env)
      env[described_class::STICK_OBJECT]
    end

    where(:path) do
      %w[
        /api/v4/jobs/42
        /api/v4/jobs/42/trace
        /api/v4/jobs/42/artifacts
        /api/v4/jobs/42/artifacts/authorize
        /api/v4/jobs/42.json
      ]
    end

    with_them do
      it 'adds the build with the id as a String' do
        expect(stick_objects_for(path)).to contain_exactly([build_sticking, :build, '42'])
      end
    end

    it 'keeps entries already in the stick object' do
      other = [build_sticking, :runner, 'token']

      expect(stick_objects_for('/api/v4/jobs/42', described_class::STICK_OBJECT => Set[other]))
        .to contain_exactly(other, [build_sticking, :build, '42'])
    end

    it 'reads the path without the relative URL root' do
      expect(stick_objects_for('/api/v4/jobs/42', 'SCRIPT_NAME' => '/gitlab'))
        .to contain_exactly([build_sticking, :build, '42'])
    end

    context 'with any other path' do
      where(:path) do
        %w[
          /api/v4/jobs
          /api/v4/jobs/request
          /api/v4/jobs/42abc
          /api/v4/projects/42/jobs/43
          /group/project/-/jobs/42
        ]
      end

      with_them do
        it 'adds nothing' do
          expect(stick_objects_for(path)).to be_nil
        end
      end
    end

    context 'when stick_runner_job_requests_before_rate_limit is disabled' do
      before do
        stub_feature_flags(stick_runner_job_requests_before_rate_limit: false)
      end

      it 'adds nothing, leaving the build to the endpoint' do
        expect(stick_objects_for('/api/v4/jobs/42')).to be_nil
      end
    end

    context 'with a session user' do
      it 'adds nothing, because the user replaces the stick object' do
        expect(stick_objects_for('/api/v4/jobs/42', 'warden' => warden_user)).to be_nil
      end

      context 'when grab_user_id_from_warden_session is enabled' do
        before do
          stub_feature_flags(grab_user_id_from_warden_session: true)
        end

        it 'adds nothing for a user in rack.session' do
          session_key = Warden::SessionSerializer.new({}).key_for(:user)
          env = { 'warden' => warden_user_no_preload, 'rack.session' => { session_key => [[42], 'session'] } }

          expect(stick_objects_for('/api/v4/jobs/42', env)).to be_nil
        end
      end
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
    it 'clears the currently used host and session with force' do
      session = spy(:session)

      stub_const('Gitlab::Database::LoadBalancing::SessionMap', session)

      expect(Gitlab::Database::LoadBalancing).to receive(:release_hosts).with(force: true)

      middleware.clear

      expect(session).to have_received(:clear_session)
    end
  end

  describe '#sticking_namespaces' do
    context 'using a Warden request' do
      context 'when grab_user_id_from_warden_session is disabled (default)' do
        before do
          stub_feature_flags(grab_user_id_from_warden_session: false)
        end

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

      # TODO: Remove the feature flag and promote these behaviours to the default when
      # grab_user_id_from_warden_session is fully rolled out
      context 'when grab_user_id_from_warden_session is enabled' do
        before do
          stub_feature_flags(grab_user_id_from_warden_session: true)
        end

        it 'returns the user id from the session without loading the user object' do
          session_key = Warden::SessionSerializer.new({}).key_for(:user)
          env = {
            'warden' => warden_user_no_preload,
            'rack.session' => { session_key => [[42], 'session'] }
          }
          ids = Gitlab::Database::LoadBalancing.base_models.map do |model|
            [model.sticking, :user, 42]
          end

          expect(warden_user_no_preload).not_to receive(:user)
          expect(middleware.sticking_namespaces(env)).to eq(ids)
        end

        it 'returns an empty Array if rack.session is missing' do
          env = { 'warden' => warden_user_no_preload }

          expect(middleware.sticking_namespaces(env)).to eq([])
        end
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
