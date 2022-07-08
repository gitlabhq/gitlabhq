# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwarenessSession do
  subject { AwarenessSession.for(session_id) }

  let!(:user) { create(:user) }
  let(:session_id) { 1 }

  after do
    redis_shared_state_cleanup!
  end

  describe "when a user joins a session" do
    let(:user2) { create(:user) }

    let(:presence_ttl) { 15.minutes }

    it "changes number of session members" do
      expect { subject.join(user) }.to change(subject, :size).by(1)
    end

    it "returns user as member of session with last_activity timestamp" do
      freeze_time do
        subject.join(user)

        session_users = subject.users_with_last_activity
        session_user, last_activity = session_users.first

        expect(session_user.id).to be(user.id)
        expect(last_activity).to be_eql(Time.now.utc)
      end
    end

    it "maintains user ID and last_activity pairs" do
      now = Time.zone.now

      travel_to now - 1.minute do
        subject.join(user2)
      end

      travel_to now do
        subject.join(user)
      end

      session_users = subject.users_with_last_activity

      expect(session_users[0].first.id).to eql(user.id)
      expect(session_users[0].last.to_i).to eql(now.to_i)

      expect(session_users[1].first.id).to eql(user2.id)
      expect(session_users[1].last.to_i).to eql((now - 1.minute).to_i)
    end

    it "reports user as present" do
      freeze_time do
        subject.join(user)

        expect(subject.present?(user, threshold: presence_ttl)).to be true
      end
    end

    it "reports user as away after a certain time on inactivity" do
      subject.join(user)

      travel_to((presence_ttl + 1.minute).from_now) do
        expect(subject.away?(user, threshold: presence_ttl)).to be true
      end
    end

    it "reports user as present still when there was some activity" do
      subject.join(user)

      travel_to((presence_ttl - 1.minute).from_now) do
        subject.touch!(user)
      end

      travel_to((presence_ttl + 1.minute).from_now) do
        expect(subject.present?(user, threshold: presence_ttl)).to be true
      end
    end

    it "creates user and session awareness keys in store" do
      subject.join(user)

      Gitlab::Redis::SharedState.with do |redis|
        keys = redis.scan_each(match: "gitlab:awareness:*").to_a

        expect(keys.size).to be(2)
      end
    end

    it "sets a timeout for user and session key" do
      subject.join(user)
      subject_id = Digest::SHA256.hexdigest(session_id.to_s)[0, 15]

      Gitlab::Redis::SharedState.with do |redis|
        ttl_session = redis.ttl("gitlab:awareness:session:#{subject_id}:users")
        ttl_user = redis.ttl("gitlab:awareness:user:#{user.id}:sessions")

        expect(ttl_session).to be > 0
        expect(ttl_user).to be > 0
      end
    end
  end

  describe "when a user leaves a session" do
    it "changes number of session members" do
      subject.join(user)

      expect { subject.leave(user) }.to change(subject, :size).by(-1)
    end

    it "destroys the session when it was the last user" do
      subject.join(user)

      expect { subject.leave(user) }.to change(subject, :id).to(nil)
    end
  end

  describe "when last user leaves a session" do
    it "session and user keys are removed" do
      subject.join(user)

      Gitlab::Redis::SharedState.with do |redis|
        expect { subject.leave(user) }
          .to change { redis.scan_each(match: "gitlab:awareness:*").to_a.size }
                .to(0)
      end
    end
  end
end
