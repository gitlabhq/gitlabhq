require 'rails_helper'

RSpec.describe ActiveSession, :clean_gitlab_redis_shared_state do
  let(:user) do
    create(:user).tap do |user|
      user.current_sign_in_at = Time.current
    end
  end

  let(:session) { double(:session, id: '6919a6f1bb119dd7396fadc38fd18d0d') }

  let(:request) do
    double(:request, {
      user_agent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 8_1_3 like Mac OS X) AppleWebKit/600.1.4 ' \
        '(KHTML, like Gecko) Mobile/12B466 [FBDV/iPhone7,2]',
      ip: '127.0.0.1',
      session: session
    })
  end

  describe '#current?' do
    it 'returns true if the active session matches the current session' do
      active_session = ActiveSession.new(session_id: '6919a6f1bb119dd7396fadc38fd18d0d')

      expect(active_session.current?(session)).to be true
    end

    it 'returns false if the active session does not match the current session' do
      active_session = ActiveSession.new(session_id: '59822c7d9fcdfa03725eff41782ad97d')

      expect(active_session.current?(session)).to be false
    end

    it 'returns false if the session id is nil' do
      active_session = ActiveSession.new(session_id: nil)
      session = double(:session, id: nil)

      expect(active_session.current?(session)).to be false
    end
  end

  describe '.list' do
    it 'returns all sessions by user' do
      Gitlab::Redis::SharedState.with do |redis|
        redis.set("session:user:gitlab:#{user.id}:6919a6f1bb119dd7396fadc38fd18d0d", Marshal.dump({ session_id: 'a' }))
        redis.set("session:user:gitlab:#{user.id}:59822c7d9fcdfa03725eff41782ad97d", Marshal.dump({ session_id: 'b' }))
        redis.set("session:user:gitlab:9999:5c8611e4f9c69645ad1a1492f4131358", '')

        redis.sadd(
          "session:lookup:user:gitlab:#{user.id}",
          %w[
            6919a6f1bb119dd7396fadc38fd18d0d
            59822c7d9fcdfa03725eff41782ad97d
          ]
        )
      end

      expect(ActiveSession.list(user)).to match_array [{ session_id: 'a' }, { session_id: 'b' }]
    end

    it 'does not return obsolete entries and cleans them up' do
      Gitlab::Redis::SharedState.with do |redis|
        redis.set("session:user:gitlab:#{user.id}:6919a6f1bb119dd7396fadc38fd18d0d", Marshal.dump({ session_id: 'a' }))

        redis.sadd(
          "session:lookup:user:gitlab:#{user.id}",
          %w[
            6919a6f1bb119dd7396fadc38fd18d0d
            59822c7d9fcdfa03725eff41782ad97d
          ]
        )
      end

      expect(ActiveSession.list(user)).to eq [{ session_id: 'a' }]

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.sscan_each("session:lookup:user:gitlab:#{user.id}").to_a).to eq ['6919a6f1bb119dd7396fadc38fd18d0d']
      end
    end

    it 'returns an empty array if the use does not have any active session' do
      expect(ActiveSession.list(user)).to eq []
    end
  end

  describe '.set' do
    it 'sets a new redis entry for the user session and a lookup entry' do
      ActiveSession.set(user, request)

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.scan_each.to_a).to match_array [
          "session:user:gitlab:#{user.id}:6919a6f1bb119dd7396fadc38fd18d0d",
          "session:lookup:user:gitlab:#{user.id}"
        ]
      end
    end

    it 'adds timestamps and information from the request' do
      Timecop.freeze(Time.zone.parse('2018-03-12 09:06')) do
        ActiveSession.set(user, request)

        session = ActiveSession.list(user)

        expect(session.count).to eq 1
        expect(session.first).to have_attributes(
          ip_address: '127.0.0.1',
          browser: 'Mobile Safari',
          os: 'iOS',
          device_name: 'iPhone 6',
          device_type: 'smartphone',
          created_at: Time.zone.parse('2018-03-12 09:06'),
          updated_at: Time.zone.parse('2018-03-12 09:06'),
          session_id: '6919a6f1bb119dd7396fadc38fd18d0d'
        )
      end
    end

    it 'keeps the created_at from the login on consecutive requests' do
      now = Time.zone.parse('2018-03-12 09:06')

      Timecop.freeze(now) do
        ActiveSession.set(user, request)

        Timecop.freeze(now + 1.minute) do
          ActiveSession.set(user, request)

          session = ActiveSession.list(user)

          expect(session.first).to have_attributes(
            created_at: Time.zone.parse('2018-03-12 09:06'),
            updated_at: Time.zone.parse('2018-03-12 09:07')
          )
        end
      end
    end
  end

  describe '.destroy' do
    it 'removes the entry associated with the currently killed user session' do
      Gitlab::Redis::SharedState.with do |redis|
        redis.set("session:user:gitlab:#{user.id}:6919a6f1bb119dd7396fadc38fd18d0d", '')
        redis.set("session:user:gitlab:#{user.id}:59822c7d9fcdfa03725eff41782ad97d", '')
        redis.set("session:user:gitlab:9999:5c8611e4f9c69645ad1a1492f4131358", '')
      end

      ActiveSession.destroy(user, request.session.id)

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.scan_each(match: "session:user:gitlab:*")).to match_array [
          "session:user:gitlab:#{user.id}:59822c7d9fcdfa03725eff41782ad97d",
          "session:user:gitlab:9999:5c8611e4f9c69645ad1a1492f4131358"
        ]
      end
    end

    it 'removes the lookup entry' do
      Gitlab::Redis::SharedState.with do |redis|
        redis.set("session:user:gitlab:#{user.id}:6919a6f1bb119dd7396fadc38fd18d0d", '')
        redis.sadd("session:lookup:user:gitlab:#{user.id}", '6919a6f1bb119dd7396fadc38fd18d0d')
      end

      ActiveSession.destroy(user, request.session.id)

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.scan_each(match: "session:lookup:user:gitlab:#{user.id}").to_a).to be_empty
      end
    end

    it 'removes the devise session' do
      Gitlab::Redis::SharedState.with do |redis|
        redis.set("session:user:gitlab:#{user.id}:6919a6f1bb119dd7396fadc38fd18d0d", '')
        redis.set("session:gitlab:6919a6f1bb119dd7396fadc38fd18d0d", '')
      end

      ActiveSession.destroy(user, request.session.id)

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.scan_each(match: "session:gitlab:*").to_a).to be_empty
      end
    end

    it 'does not remove the devise session if the active session could not be found' do
      Gitlab::Redis::SharedState.with do |redis|
        redis.set("session:gitlab:6919a6f1bb119dd7396fadc38fd18d0d", '')
      end

      other_user = create(:user)

      ActiveSession.destroy(other_user, request.session.id)

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.scan_each(match: "session:gitlab:*").to_a).not_to be_empty
      end
    end
  end

  describe '.cleanup' do
    it 'removes obsolete lookup entries' do
      Gitlab::Redis::SharedState.with do |redis|
        redis.set("session:user:gitlab:#{user.id}:6919a6f1bb119dd7396fadc38fd18d0d", '')
        redis.sadd("session:lookup:user:gitlab:#{user.id}", '6919a6f1bb119dd7396fadc38fd18d0d')
        redis.sadd("session:lookup:user:gitlab:#{user.id}", '59822c7d9fcdfa03725eff41782ad97d')
      end

      ActiveSession.cleanup(user)

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.smembers("session:lookup:user:gitlab:#{user.id}")).to eq ['6919a6f1bb119dd7396fadc38fd18d0d']
      end
    end

    it 'does not bail if there are no lookup entries' do
      ActiveSession.cleanup(user)
    end
  end
end
