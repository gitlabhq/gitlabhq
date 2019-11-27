# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveSession, :clean_gitlab_redis_shared_state do
  let(:user) do
    create(:user).tap do |user|
      user.current_sign_in_at = Time.current
    end
  end

  let(:session) do
    double(:session, { id: '6919a6f1bb119dd7396fadc38fd18d0d',
                       '[]': {} })
  end

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

  describe '.list_sessions' do
    it 'uses the ActiveSession lookup to return original sessions' do
      Gitlab::Redis::SharedState.with do |redis|
        redis.set("session:gitlab:6919a6f1bb119dd7396fadc38fd18d0d", Marshal.dump({ _csrf_token: 'abcd' }))

        redis.sadd(
          "session:lookup:user:gitlab:#{user.id}",
          %w[
            6919a6f1bb119dd7396fadc38fd18d0d
            59822c7d9fcdfa03725eff41782ad97d
          ]
        )
      end

      expect(ActiveSession.list_sessions(user)).to eq [{ _csrf_token: 'abcd' }]
    end
  end

  describe '.session_ids_for_user' do
    it 'uses the user lookup table to return session ids' do
      session_ids = ['59822c7d9fcdfa03725eff41782ad97d']

      Gitlab::Redis::SharedState.with do |redis|
        redis.sadd("session:lookup:user:gitlab:#{user.id}", session_ids)
      end

      expect(ActiveSession.session_ids_for_user(user.id)).to eq(session_ids)
    end
  end

  describe '.sessions_from_ids' do
    it 'uses the ActiveSession lookup to return original sessions' do
      Gitlab::Redis::SharedState.with do |redis|
        redis.set("session:gitlab:6919a6f1bb119dd7396fadc38fd18d0d", Marshal.dump({ _csrf_token: 'abcd' }))
      end

      expect(ActiveSession.sessions_from_ids(['6919a6f1bb119dd7396fadc38fd18d0d'])).to eq [{ _csrf_token: 'abcd' }]
    end

    it 'avoids a redis lookup for an empty array' do
      expect(Gitlab::Redis::SharedState).not_to receive(:with)

      expect(ActiveSession.sessions_from_ids([])).to eq([])
    end

    it 'uses redis lookup in batches' do
      stub_const('ActiveSession::SESSION_BATCH_SIZE', 1)

      redis = double(:redis)
      expect(Gitlab::Redis::SharedState).to receive(:with).and_yield(redis)

      sessions = ['session-a', 'session-b']
      mget_responses = sessions.map { |session| [Marshal.dump(session)]}
      expect(redis).to receive(:mget).twice.and_return(*mget_responses)

      expect(ActiveSession.sessions_from_ids([1, 2])).to eql(sessions)
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
  end

  describe '.cleanup' do
    before do
      stub_const("ActiveSession::ALLOWED_NUMBER_OF_ACTIVE_SESSIONS", 5)
    end

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

    context 'cleaning up old sessions' do
      let(:max_number_of_sessions_plus_one) { ActiveSession::ALLOWED_NUMBER_OF_ACTIVE_SESSIONS + 1 }
      let(:max_number_of_sessions_plus_two) { ActiveSession::ALLOWED_NUMBER_OF_ACTIVE_SESSIONS + 2 }

      before do
        Gitlab::Redis::SharedState.with do |redis|
          (1..max_number_of_sessions_plus_two).each do |number|
            redis.set(
              "session:user:gitlab:#{user.id}:#{number}",
              Marshal.dump(ActiveSession.new(session_id: "#{number}", updated_at: number.days.ago))
            )
            redis.sadd(
              "session:lookup:user:gitlab:#{user.id}",
              "#{number}"
            )
          end
        end
      end

      it 'removes obsolete active sessions entries' do
        ActiveSession.cleanup(user)

        Gitlab::Redis::SharedState.with do |redis|
          sessions = redis.scan_each(match: "session:user:gitlab:#{user.id}:*").to_a

          expect(sessions.count).to eq(ActiveSession::ALLOWED_NUMBER_OF_ACTIVE_SESSIONS)
          expect(sessions).not_to include("session:user:gitlab:#{user.id}:#{max_number_of_sessions_plus_one}", "session:user:gitlab:#{user.id}:#{max_number_of_sessions_plus_two}")
        end
      end

      it 'removes obsolete lookup entries' do
        ActiveSession.cleanup(user)

        Gitlab::Redis::SharedState.with do |redis|
          lookup_entries = redis.smembers("session:lookup:user:gitlab:#{user.id}")

          expect(lookup_entries.count).to eq(ActiveSession::ALLOWED_NUMBER_OF_ACTIVE_SESSIONS)
          expect(lookup_entries).not_to include(max_number_of_sessions_plus_one.to_s, max_number_of_sessions_plus_two.to_s)
        end
      end
    end
  end
end
