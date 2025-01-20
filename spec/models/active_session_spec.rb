# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveSession, :clean_gitlab_redis_sessions, feature_category: :system_access do
  let(:lookup_key) { described_class.lookup_key_name(user.id) }
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
      active_session = described_class.new(session_private_id: rack_session.private_id)

      expect(active_session.current?(session)).to be true
    end

    it 'returns false if the active session does not match the current session' do
      active_session = described_class.new(session_id: Rack::Session::SessionId.new('59822c7d9fcdfa03725eff41782ad97d'))

      expect(active_session.current?(session)).to be false
    end

    it 'returns false if the session id is nil' do
      active_session = described_class.new(session_id: nil)
      session = double(:session, id: nil)

      expect(active_session.current?(session)).to be false
    end
  end

  describe '.list' do
    def make_session(id)
      described_class.new(session_id: id)
    end

    it 'returns all sessions by user' do
      Gitlab::Redis::Sessions.with do |redis|
        # Some deprecated sessions
        redis.set(described_class.key_name_v1(user.id, "6919a6f1bb119dd7396fadc38fd18d0d"), Marshal.dump(make_session('a')))
        redis.set(described_class.key_name_v1(user.id, "59822c7d9fcdfa03725eff41782ad97d"), Marshal.dump(make_session('b')))
        # Some new sessions
        redis.set(described_class.key_name(user.id, 'some-unique-id-x'), make_session('c').dump)
        redis.set(described_class.key_name(user.id, 'some-unique-id-y'), make_session('d').dump)
        # Some red herrings
        redis.set(described_class.key_name(9999, "5c8611e4f9c69645ad1a1492f4131358"), 'irrelevant')
        redis.set(described_class.key_name_v1(9999, "5c8611e4f9c69645ad1a1492f4131358"), 'irrelevant')

        redis.sadd(
          lookup_key,
          %w[
            6919a6f1bb119dd7396fadc38fd18d0d
            59822c7d9fcdfa03725eff41782ad97d
            some-unique-id-x
            some-unique-id-y
          ]
        )
      end

      expect(described_class.list(user)).to contain_exactly(
        have_attributes(session_id: 'a'),
        have_attributes(session_id: 'b'),
        have_attributes(session_id: 'c'),
        have_attributes(session_id: 'd')
      )
    end

    it 'returns an empty array if the user does not have any active session' do
      expect(described_class.list(user)).to be_empty
    end

    shared_examples 'ignoring obsolete entries' do
      let(:session_id) { '6919a6f1bb119dd7396fadc38fd18d0d' }
      let(:session) { described_class.new(session_id: 'a') }

      it 'does not return obsolete entries and cleans them up' do
        Gitlab::Redis::Sessions.with do |redis|
          redis.set(session_key, serialized_session)

          redis.sadd(
            lookup_key,
            [
              session_id,
              '59822c7d9fcdfa03725eff41782ad97d'
            ]
          )
        end

        expect(described_class.list(user)).to contain_exactly(session)

        Gitlab::Redis::Sessions.with do |redis|
          expect(redis.sscan_each(lookup_key)).to contain_exactly session_id
        end
      end
    end

    context 'when the current session is in the old format' do
      let(:session_key) { described_class.key_name_v1(user.id, session_id) }
      let(:serialized_session) { Marshal.dump(session) }

      it_behaves_like 'ignoring obsolete entries'
    end

    context 'when the current session is in the new format' do
      let(:session_key) { described_class.key_name(user.id, session_id) }
      let(:serialized_session) { session.dump }

      it_behaves_like 'ignoring obsolete entries'

      context 'when the current session contains unknown attributes' do
        let(:session_id) { '8f62cc7383c' }
        let(:session_key) { described_class.key_name(user.id, session_id) }
        let(:serialized_session) do
          "v2:{\"ip_address\": \"127.0.0.1\", \"browser\": \"Firefox\", \"os\": \"Debian\", " \
            "\"device_type\": \"desktop\", \"session_id\": \"#{session_id}\", " \
            "\"new_attribute\": \"unknown attribute\"}"
        end

        it 'loads known attributes only' do
          Gitlab::Redis::Sessions.with do |redis|
            redis.set(session_key, serialized_session)
            redis.sadd(lookup_key, [session_id])
          end

          expect(described_class.list(user)).to contain_exactly(
            have_attributes(
              ip_address: "127.0.0.1",
              browser: "Firefox",
              os: "Debian",
              device_type: "desktop",
              session_id: session_id.to_s
            )
          )
          expect(described_class.list(user).first).not_to respond_to :new_attribute
        end
      end
    end
  end

  describe '.list_sessions' do
    it 'uses the ActiveSession lookup to return original sessions' do
      Gitlab::Redis::Sessions.with do |redis|
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

      expect(described_class.list_sessions(user)).to eq [{ _csrf_token: 'abcd' }]
    end
  end

  describe '.session_ids_for_user' do
    it 'uses the user lookup table to return session ids' do
      Gitlab::Redis::Sessions.with do |redis|
        redis.sadd(lookup_key, %w[a b c])
      end

      expect(described_class.session_ids_for_user(user.id).map(&:to_s)).to match_array(%w[a b c])
    end
  end

  describe '.sessions_from_ids' do
    context 'with new session format from Gitlab::Sessions::CacheStore' do
      before do
        store = ActiveSupport::Cache::RedisCacheStore.new(
          namespace: Gitlab::Redis::Sessions::SESSION_NAMESPACE,
          redis: Gitlab::Redis::Sessions
        )
        # ActiveSupport::Cache::RedisCacheStore wraps the data in ActiveSupport::Cache::Entry
        # https://github.com/rails/rails/blob/v7.0.8.6/activesupport/lib/active_support/cache.rb#L506
        store.write(rack_session.private_id, { _csrf_token: 'abcd' })
      end

      it 'uses the ActiveSession lookup to return original sessions' do
        expect(described_class.sessions_from_ids([rack_session.private_id])).to eq [{ _csrf_token: 'abcd' }]
      end
    end

    context 'with old session format from Gitlab::Sessions::RedisStore' do
      it 'uses the ActiveSession lookup to return original sessions' do
        Gitlab::Redis::Sessions.with do |redis|
          # Emulate redis-rack: https://github.com/redis-store/redis-rack/blob/c75f7f1a6016ee224e2615017fbfee964f23a837/lib/rack/session/redis.rb#L88
          redis.set("session:gitlab:#{rack_session.private_id}", Marshal.dump({ _csrf_token: 'abcd' }))
        end

        expect(described_class.sessions_from_ids([rack_session.private_id])).to eq [{ _csrf_token: 'abcd' }]
      end
    end

    it 'avoids a redis lookup for an empty array' do
      expect(Gitlab::Redis::Sessions).not_to receive(:with)

      expect(described_class.sessions_from_ids([])).to eq([])
    end

    it 'uses redis lookup in batches' do
      stub_const('ActiveSession::SESSION_BATCH_SIZE', 1)

      redis = double(:redis)
      expect(Gitlab::Redis::Sessions).to receive(:with).and_yield(redis)

      sessions = %w[session-a session-b]
      mget_responses = sessions.map { |session| [Marshal.dump(session)] }
      expect(redis).to receive(:mget).twice.times.and_return(*mget_responses)

      expect(described_class.sessions_from_ids([1, 2])).to eql(sessions)
    end
  end

  describe '.set' do
    it 'sets a new redis entry for the user session and a lookup entry' do
      described_class.set(user, request)

      session_id = "2::418729c72310bbf349a032f0bb6e3fce9f5a69df8f000d8ae0ac5d159d8f21ae"

      Gitlab::Redis::Sessions.with do |redis|
        expect(redis.scan_each.to_a).to include(
          described_class.key_name(user.id, session_id), # current session
          lookup_key
        )
      end
    end

    it 'adds timestamps and information from the request' do
      time = Time.zone.parse('2018-03-12 09:06')

      travel_to(time) do
        described_class.set(user, request)

        sessions = described_class.list(user)

        expect(sessions).to contain_exactly have_attributes(
          ip_address: '127.0.0.1',
          browser: 'Mobile Safari',
          os: 'iOS',
          device_name: 'iPhone 6',
          device_type: 'smartphone',
          created_at: eq(time),
          updated_at: eq(time)
        )
      end
    end

    it 'keeps the created_at from the login on consecutive requests' do
      created_at = Time.zone.parse('2018-03-12 09:06')
      updated_at = created_at + 1.minute

      travel_to(created_at) do
        ActiveSession.set(user, request)
      end

      travel_to(updated_at) do
        ActiveSession.set(user, request)

        session = ActiveSession.list(user)

        expect(session.first).to have_attributes(
          created_at: eq(created_at),
          updated_at: eq(updated_at)
        )
      end
    end
  end

  describe '.destroy_session' do
    shared_examples 'removes all session data' do
      before do
        Gitlab::Redis::Sessions.with do |redis|
          redis.set("session:user:gitlab:#{user.id}:#{active_session_lookup_key}", '')
          # Emulate redis-rack: https://github.com/redis-store/redis-rack/blob/c75f7f1a6016ee224e2615017fbfee964f23a837/lib/rack/session/redis.rb#L88
          redis.set("session:gitlab:#{rack_session.private_id}", '')

          redis.set(session_key, serialized_session)
          redis.sadd?(lookup_key, active_session_lookup_key)
        end
      end

      it 'removes the devise session' do
        subject

        Gitlab::Redis::Sessions.with do |redis|
          expect(redis.scan_each(match: "session:gitlab:*").to_a).to be_empty
        end
      end

      it 'removes the lookup entry' do
        subject

        Gitlab::Redis::Sessions.with do |redis|
          expect(redis.scan_each(match: lookup_key).to_a).to be_empty
        end
      end

      it 'removes the ActiveSession' do
        subject

        Gitlab::Redis::Sessions.with do |redis|
          expect(redis.scan_each(match: "session:user:gitlab:*").to_a).to be_empty
        end
      end
    end

    context 'destroy called with Rack::Session::SessionId#private_id' do
      subject { described_class.destroy_session(user, rack_session.private_id) }

      it 'calls .destroy_sessions' do
        expect(described_class).to(
          receive(:destroy_sessions)
            .with(anything, user, [rack_session.private_id]))

        subject
      end

      context 'ActiveSession with session_private_id' do
        let(:active_session) { described_class.new(session_private_id: rack_session.private_id) }
        let(:active_session_lookup_key) { rack_session.private_id }

        context 'when using old session key serialization' do
          let(:session_key) { described_class.key_name_v1(user.id, active_session_lookup_key) }
          let(:serialized_session) { Marshal.dump(active_session) }

          include_examples 'removes all session data'
        end

        context 'when using new session key serialization' do
          let(:session_key) { described_class.key_name(user.id, active_session_lookup_key) }
          let(:serialized_session) { active_session.dump }

          include_examples 'removes all session data'
        end
      end
    end
  end

  describe '.destroy_all_but_current' do
    it 'gracefully handles a nil session ID' do
      expect(described_class).not_to receive(:destroy_sessions)

      described_class.destroy_all_but_current(user, nil)
    end

    shared_examples 'with user sessions' do
      let(:current_session_id) { '6919a6f1bb119dd7396fadc38fd18d0d' }

      before do
        Gitlab::Redis::Sessions.with do |redis|
          # setup for current user
          [current_session_id, '59822c7d9fcdfa03725eff41782ad97d'].each do |session_public_id|
            session_private_id = Rack::Session::SessionId.new(session_public_id).private_id
            active_session = ActiveSession.new(session_private_id: session_private_id)
            redis.set(key_name(user.id, session_private_id), dump_session(active_session))
            redis.sadd?(lookup_key, session_private_id)
          end

          # setup for unrelated user
          unrelated_user_id = 9999
          session_private_id = Rack::Session::SessionId.new('5c8611e4f9c69645ad1a1492f4131358').private_id
          active_session = ActiveSession.new(session_private_id: session_private_id)

          redis.set(key_name(unrelated_user_id, session_private_id), dump_session(active_session))
          redis.sadd?(described_class.lookup_key_name(unrelated_user_id), session_private_id)
        end
      end

      it 'removes the entry associated with the all user sessions but current' do
        expect { described_class.destroy_all_but_current(user, request.session) }
          .to(change { ActiveSession.session_ids_for_user(user.id).size }.from(2).to(1))

        expect(described_class.session_ids_for_user(9999).size).to eq(1)
      end

      it 'removes the lookup entry of deleted sessions' do
        session_private_id = Rack::Session::SessionId.new(current_session_id).private_id
        described_class.destroy_all_but_current(user, request.session)

        Gitlab::Redis::Sessions.with do |redis|
          expect(redis.smembers(lookup_key)).to contain_exactly session_private_id
        end
      end

      it 'does not remove impersonated sessions' do
        impersonated_session_id = '6919a6f1bb119dd7396fadc38fd18eee'
        Gitlab::Redis::Sessions.with do |redis|
          redis.set(key_name(user.id, impersonated_session_id),
            dump_session(ActiveSession.new(session_id: Rack::Session::SessionId.new(impersonated_session_id), is_impersonated: true)))
          redis.sadd?(lookup_key, impersonated_session_id)
        end

        expect { described_class.destroy_all_but_current(user, request.session) }.to change { ActiveSession.session_ids_for_user(user.id).size }.from(3).to(2)

        expect(described_class.session_ids_for_user(9999).size).to eq(1)
      end
    end

    context 'with legacy sessions' do
      def key_name(user_id, id)
        described_class.key_name_v1(user_id, id)
      end

      def dump_session(session)
        Marshal.dump(session)
      end

      it_behaves_like 'with user sessions'
    end

    context 'with new sessions' do
      def key_name(user_id, id)
        described_class.key_name(user_id, id)
      end

      def dump_session(session)
        session.dump
      end

      it_behaves_like 'with user sessions'
    end
  end

  describe '.cleanup' do
    before do
      stub_const("ActiveSession::ALLOWED_NUMBER_OF_ACTIVE_SESSIONS", 5)
    end

    shared_examples 'cleaning up' do
      context 'when removing obsolete sessions' do
        let(:current_session_id) { '6919a6f1bb119dd7396fadc38fd18d0d' }

        it 'removes obsolete lookup entries' do
          Gitlab::Redis::Sessions.with do |redis|
            redis.set(session_key, '')
            redis.sadd(lookup_key, [current_session_id, '59822c7d9fcdfa03725eff41782ad97d'])
          end

          described_class.cleanup(user)

          Gitlab::Redis::Sessions.with do |redis|
            expect(redis.smembers(lookup_key)).to contain_exactly current_session_id
          end
        end
      end

      it 'does not bail if there are no lookup entries' do
        described_class.cleanup(user)
      end

      context 'cleaning up old sessions' do
        let(:max_number_of_sessions_plus_one) { ActiveSession::ALLOWED_NUMBER_OF_ACTIVE_SESSIONS + 1 }
        let(:max_number_of_sessions_plus_two) { ActiveSession::ALLOWED_NUMBER_OF_ACTIVE_SESSIONS + 2 }

        before do
          Gitlab::Redis::Sessions.with do |redis|
            max_number_of_sessions_plus_two.times do |number|
              redis.set(
                key_name(user.id, number),
                dump_session(ActiveSession.new(session_id: number.to_s, updated_at: number.days.ago))
              )
              redis.sadd?(lookup_key, number.to_s)
            end
          end
        end

        it 'removes obsolete active sessions entries' do
          described_class.cleanup(user)

          Gitlab::Redis::Sessions.with do |redis|
            sessions = described_class.list(user)

            expect(sessions.count).to eq(ActiveSession::ALLOWED_NUMBER_OF_ACTIVE_SESSIONS)
            expect(sessions).not_to include(
              have_attributes(session_id: max_number_of_sessions_plus_one),
              have_attributes(session_id: max_number_of_sessions_plus_two)
            )
          end
        end

        it 'removes obsolete lookup entries' do
          described_class.cleanup(user)

          Gitlab::Redis::Sessions.with do |redis|
            lookup_entries = redis.smembers(lookup_key)

            expect(lookup_entries.count).to eq(ActiveSession::ALLOWED_NUMBER_OF_ACTIVE_SESSIONS)
            expect(lookup_entries).not_to include(max_number_of_sessions_plus_one.to_s, max_number_of_sessions_plus_two.to_s)
          end
        end

        it 'removes obsolete lookup entries even without active session' do
          Gitlab::Redis::Sessions.with do |redis|
            redis.sadd?(lookup_key, (max_number_of_sessions_plus_two + 1).to_s)
          end

          described_class.cleanup(user)

          Gitlab::Redis::Sessions.with do |redis|
            lookup_entries = redis.smembers(lookup_key)

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
            Gitlab::Redis::Sessions.with do |redis|
              ((max_number_of_sessions_plus_two - 4)..max_number_of_sessions_plus_two).each do |number|
                redis.del(key_name(user.id, number))
              end
            end
          end

          it 'does not remove active session entries, but removes lookup entries' do
            lookup_entries_before_cleanup = Gitlab::Redis::Sessions.with do |redis|
              redis.smembers(lookup_key)
            end

            sessions_before_cleanup = described_class.list(user)

            described_class.cleanup(user)

            Gitlab::Redis::Sessions.with do |redis|
              lookup_entries = redis.smembers(lookup_key)
              sessions = described_class.list(user)

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
          Gitlab::Redis::Sessions.with do |redis|
            (1..max_number_of_sessions_plus_two).each do |number|
              redis.set(
                key_name(user.id, number),
                dump_session(ActiveSession.new(session_private_id: number.to_s, updated_at: number.days.ago))
              )
              redis.sadd?(lookup_key, number.to_s)
            end
          end
        end

        it 'removes obsolete active sessions entries' do
          described_class.cleanup(user)

          Gitlab::Redis::Sessions.with do |redis|
            sessions = described_class.list(user)

            expect(sessions.count).to eq(described_class::ALLOWED_NUMBER_OF_ACTIVE_SESSIONS)
            expect(sessions).not_to include(
              key_name(user.id, max_number_of_sessions_plus_one),
              key_name(user.id, max_number_of_sessions_plus_two)
            )
          end
        end
      end
    end

    context 'with legacy sessions' do
      let(:session_key) { described_class.key_name_v1(user.id, current_session_id) }

      def key_name(user_id, session_id)
        described_class.key_name_v1(user_id, session_id)
      end

      def dump_session(session)
        Marshal.dump(session)
      end

      it_behaves_like 'cleaning up'
    end

    context 'with new sessions' do
      let(:session_key) { described_class.key_name(user.id, current_session_id) }

      def key_name(user_id, session_id)
        described_class.key_name(user_id, session_id)
      end

      def dump_session(session)
        session.dump
      end

      it_behaves_like 'cleaning up'
    end
  end

  describe '.cleaned_up_lookup_entries' do
    before do
      stub_const("ActiveSession::ALLOWED_NUMBER_OF_ACTIVE_SESSIONS", 5)
    end

    shared_examples 'cleaning up lookup entries' do
      let(:current_session_id) { '6919a6f1bb119dd7396fadc38fd18d0d' }
      let(:active_count) { 3 }

      before do
        Gitlab::Redis::Sessions.with do |redis|
          active_count.times do |number|
            redis.set(
              key_name(user.id, number),
              dump_session(ActiveSession.new(session_id: number.to_s, updated_at: number.days.ago))
            )

            redis.sadd?(lookup_key, number.to_s)
          end

          redis.sadd?(lookup_key, [(active_count + 1).to_s, (active_count + 2).to_s])
        end
      end

      it 'removes obsolete lookup entries' do
        active = Gitlab::Redis::Sessions.with do |redis|
          ActiveSession.cleaned_up_lookup_entries(redis, user)
        end

        expect(active.count).to eq(active_count)

        Gitlab::Redis::Sessions.with do |redis|
          lookup_entries = redis.smembers(lookup_key)

          expect(lookup_entries.count).to eq(active_count)
          expect(lookup_entries).not_to include(
            (active_count + 1).to_s,
            (active_count + 2).to_s
          )
        end
      end

      it 'reports the removed entries' do
        removed = []
        Gitlab::Redis::Sessions.with do |redis|
          ActiveSession.cleaned_up_lookup_entries(redis, user, removed)
        end

        expect(removed.count).to eq(2)
      end
    end

    context 'with legacy sessions' do
      let(:session_key) { described_class.key_name_v1(user.id, current_session_id) }

      def key_name(user_id, session_id)
        described_class.key_name_v1(user_id, session_id)
      end

      def dump_session(session)
        Marshal.dump(session)
      end

      it_behaves_like 'cleaning up lookup entries'
    end

    context 'with new sessions' do
      let(:session_key) { described_class.key_name(user.id, current_session_id) }

      def key_name(user_id, session_id)
        described_class.key_name(user_id, session_id)
      end

      def dump_session(session)
        session.dump
      end

      it_behaves_like 'cleaning up lookup entries'
    end
  end
end
