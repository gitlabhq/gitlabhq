# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveSession, :clean_gitlab_redis_shared_state do
  let(:user) do
    create(:user).tap do |user|
      user.current_sign_in_at = Time.current
    end
  end

  let(:rack_session) { Rack::Session::SessionId.new('6919a6f1bb119dd7396fadc38fd18d0d') }
  let(:session) { instance_double(ActionDispatch::Request::Session, id: rack_session, '[]': {}) }

  let(:request) do
    double(:request, {
      user_agent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 8_1_3 like Mac OS X) AppleWebKit/600.1.4 ' \
        '(KHTML, like Gecko) Mobile/12B466 [FBDV/iPhone7,2]',
      remote_ip: '127.0.0.1',
      session: session
    })
  end

  describe '#current?' do
    it 'returns true if the active session matches the current session' do
      active_session = ActiveSession.new(session_private_id: rack_session.private_id)

      expect(active_session.current?(session)).to be true
    end

    it 'returns false if the active session does not match the current session' do
      active_session = ActiveSession.new(session_id: Rack::Session::SessionId.new('59822c7d9fcdfa03725eff41782ad97d'))

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
        # Emulate redis-rack: https://github.com/redis-store/redis-rack/blob/c75f7f1a6016ee224e2615017fbfee964f23a837/lib/rack/session/redis.rb#L88
        redis.set("session:gitlab:#{rack_session.private_id}", Marshal.dump({ _csrf_token: 'abcd' }))

        redis.sadd(
          "session:lookup:user:gitlab:#{user.id}",
          %w[
            2::418729c72310bbf349a032f0bb6e3fce9f5a69df8f000d8ae0ac5d159d8f21ae
            2::d2ee6f70d6ef0e8701efa3f6b281cbe8e6bf3d109ef052a8b5ce88bfc7e71c26
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

      expect(ActiveSession.session_ids_for_user(user.id).map(&:to_s)).to eq(session_ids)
    end
  end

  describe '.sessions_from_ids' do
    it 'uses the ActiveSession lookup to return original sessions' do
      Gitlab::Redis::SharedState.with do |redis|
        # Emulate redis-rack: https://github.com/redis-store/redis-rack/blob/c75f7f1a6016ee224e2615017fbfee964f23a837/lib/rack/session/redis.rb#L88
        redis.set("session:gitlab:#{rack_session.private_id}", Marshal.dump({ _csrf_token: 'abcd' }))
      end

      expect(ActiveSession.sessions_from_ids([rack_session.private_id])).to eq [{ _csrf_token: 'abcd' }]
    end

    it 'avoids a redis lookup for an empty array' do
      expect(Gitlab::Redis::SharedState).not_to receive(:with)

      expect(ActiveSession.sessions_from_ids([])).to eq([])
    end

    it 'uses redis lookup in batches' do
      stub_const('ActiveSession::SESSION_BATCH_SIZE', 1)

      redis = double(:redis)
      expect(Gitlab::Redis::SharedState).to receive(:with).and_yield(redis)

      sessions = %w[session-a session-b]
      mget_responses = sessions.map { |session| [Marshal.dump(session)]}
      expect(redis).to receive(:mget).twice.times.and_return(*mget_responses)

      expect(ActiveSession.sessions_from_ids([1, 2])).to eql(sessions)
    end
  end

  describe '.set' do
    it 'sets a new redis entry for the user session and a lookup entry' do
      ActiveSession.set(user, request)

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.scan_each.to_a).to include(
          "session:user:gitlab:#{user.id}:2::418729c72310bbf349a032f0bb6e3fce9f5a69df8f000d8ae0ac5d159d8f21ae",
          "session:lookup:user:gitlab:#{user.id}"
        )
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
          updated_at: Time.zone.parse('2018-03-12 09:06')
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

  describe '.destroy_session' do
    shared_examples 'removes all session data' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set("session:user:gitlab:#{user.id}:#{active_session_lookup_key}", '')
          # Emulate redis-rack: https://github.com/redis-store/redis-rack/blob/c75f7f1a6016ee224e2615017fbfee964f23a837/lib/rack/session/redis.rb#L88
          redis.set("session:gitlab:#{rack_session.private_id}", '')

          redis.set(described_class.key_name(user.id, active_session_lookup_key),
                    Marshal.dump(active_session))
          redis.sadd(described_class.lookup_key_name(user.id),
                     active_session_lookup_key)
        end
      end

      it 'removes the devise session' do
        subject

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.scan_each(match: "session:gitlab:*").to_a).to be_empty
        end
      end

      it 'removes the lookup entry' do
        subject

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.scan_each(match: "session:lookup:user:gitlab:#{user.id}").to_a).to be_empty
        end
      end

      it 'removes the ActiveSession' do
        subject

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.scan_each(match: "session:user:gitlab:*").to_a).to be_empty
        end
      end
    end

    context 'destroy called with Rack::Session::SessionId#private_id' do
      subject { ActiveSession.destroy_session(user, rack_session.private_id) }

      it 'calls .destroy_sessions' do
        expect(ActiveSession).to(
          receive(:destroy_sessions)
            .with(anything, user, [rack_session.private_id]))

        subject
      end

      context 'ActiveSession with session_private_id' do
        let(:active_session) { ActiveSession.new(session_private_id: rack_session.private_id) }
        let(:active_session_lookup_key) { rack_session.private_id }

        include_examples 'removes all session data'
      end
    end
  end

  describe '.destroy_all_but_current' do
    it 'gracefully handles a nil session ID' do
      expect(described_class).not_to receive(:destroy_sessions)

      ActiveSession.destroy_all_but_current(user, nil)
    end

    context 'with user sessions' do
      let(:current_session_id) { '6919a6f1bb119dd7396fadc38fd18d0d' }

      before do
        Gitlab::Redis::SharedState.with do |redis|
          # setup for current user
          [current_session_id, '59822c7d9fcdfa03725eff41782ad97d'].each do |session_public_id|
            session_private_id = Rack::Session::SessionId.new(session_public_id).private_id
            active_session = ActiveSession.new(session_private_id: session_private_id)
            redis.set(described_class.key_name(user.id, session_private_id),
                      Marshal.dump(active_session))
            redis.sadd(described_class.lookup_key_name(user.id),
                       session_private_id)
          end

          # setup for unrelated user
          unrelated_user_id = 9999
          session_private_id = Rack::Session::SessionId.new('5c8611e4f9c69645ad1a1492f4131358').private_id
          active_session = ActiveSession.new(session_private_id: session_private_id)

          redis.set(described_class.key_name(unrelated_user_id, session_private_id),
                    Marshal.dump(active_session))
          redis.sadd(described_class.lookup_key_name(unrelated_user_id),
                     session_private_id)
        end
      end

      it 'removes the entry associated with the all user sessions but current' do
        expect { ActiveSession.destroy_all_but_current(user, request.session) }
          .to(change { ActiveSession.session_ids_for_user(user.id).size }.from(2).to(1))

        expect(ActiveSession.session_ids_for_user(9999).size).to eq(1)
      end

      it 'removes the lookup entry of deleted sessions' do
        session_private_id = Rack::Session::SessionId.new(current_session_id).private_id
        ActiveSession.destroy_all_but_current(user, request.session)

        Gitlab::Redis::SharedState.with do |redis|
          expect(
            redis.smembers(described_class.lookup_key_name(user.id))
          ).to eq([session_private_id])
        end
      end

      it 'does not remove impersonated sessions' do
        impersonated_session_id = '6919a6f1bb119dd7396fadc38fd18eee'
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(described_class.key_name(user.id, impersonated_session_id),
            Marshal.dump(ActiveSession.new(session_id: Rack::Session::SessionId.new(impersonated_session_id), is_impersonated: true)))
          redis.sadd(described_class.lookup_key_name(user.id), impersonated_session_id)
        end

        expect { ActiveSession.destroy_all_but_current(user, request.session) }.to change { ActiveSession.session_ids_for_user(user.id).size }.from(3).to(2)

        expect(ActiveSession.session_ids_for_user(9999).size).to eq(1)
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
              Marshal.dump(ActiveSession.new(session_id: number.to_s, updated_at: number.days.ago))
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

      it 'removes obsolete lookup entries even without active session' do
        Gitlab::Redis::SharedState.with do |redis|
          redis.sadd(
            "session:lookup:user:gitlab:#{user.id}",
            "#{max_number_of_sessions_plus_two + 1}"
          )
        end

        ActiveSession.cleanup(user)

        Gitlab::Redis::SharedState.with do |redis|
          lookup_entries = redis.smembers("session:lookup:user:gitlab:#{user.id}")

          expect(lookup_entries.count).to eq(ActiveSession::ALLOWED_NUMBER_OF_ACTIVE_SESSIONS)
          expect(lookup_entries).not_to include(
            max_number_of_sessions_plus_one.to_s,
            max_number_of_sessions_plus_two.to_s,
            (max_number_of_sessions_plus_two + 1).to_s
          )
        end
      end

      context 'when the number of active sessions is lower than the limit' do
        before do
          Gitlab::Redis::SharedState.with do |redis|
            ((max_number_of_sessions_plus_two - 4)..max_number_of_sessions_plus_two).each do |number|
              redis.del("session:user:gitlab:#{user.id}:#{number}")
            end
          end
        end

        it 'does not remove active session entries, but removes lookup entries' do
          lookup_entries_before_cleanup = Gitlab::Redis::SharedState.with do |redis|
            redis.smembers("session:lookup:user:gitlab:#{user.id}")
          end

          sessions_before_cleanup = Gitlab::Redis::SharedState.with do |redis|
            redis.scan_each(match: "session:user:gitlab:#{user.id}:*").to_a
          end

          ActiveSession.cleanup(user)

          Gitlab::Redis::SharedState.with do |redis|
            lookup_entries = redis.smembers("session:lookup:user:gitlab:#{user.id}")
            sessions = redis.scan_each(match: "session:user:gitlab:#{user.id}:*").to_a
            expect(sessions.count).to eq(sessions_before_cleanup.count)
            expect(lookup_entries.count).to be < lookup_entries_before_cleanup.count
          end
        end
      end
    end

    context 'cleaning up old sessions stored by Rack::Session::SessionId#private_id' do
      let(:max_number_of_sessions_plus_one) { ActiveSession::ALLOWED_NUMBER_OF_ACTIVE_SESSIONS + 1 }
      let(:max_number_of_sessions_plus_two) { ActiveSession::ALLOWED_NUMBER_OF_ACTIVE_SESSIONS + 2 }

      before do
        Gitlab::Redis::SharedState.with do |redis|
          (1..max_number_of_sessions_plus_two).each do |number|
            redis.set(
              "session:user:gitlab:#{user.id}:#{number}",
              Marshal.dump(ActiveSession.new(session_private_id: number.to_s, updated_at: number.days.ago))
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
          expect(sessions).not_to(
            include("session:user:gitlab:#{user.id}:#{max_number_of_sessions_plus_one}",
                    "session:user:gitlab:#{user.id}:#{max_number_of_sessions_plus_two}"))
        end
      end
    end
  end
end
