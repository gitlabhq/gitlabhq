# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Awareness do
  subject { create(:user) }

  let(:session) { AwarenessSession.for(1) }

  after do
    redis_shared_state_cleanup!
  end

  describe "when joining a session" do
    it "increases the number of sessions" do
      expect { subject.join(session) }
        .to change { subject.session_ids.size }
              .by(1)
    end
  end

  describe "when leaving session" do
    it "decreases the number of sessions" do
      subject.join(session)

      expect { subject.leave(session) }
        .to change { subject.session_ids.size }
              .by(-1)
    end
  end

  describe "when joining multiple sessions" do
    let(:session2) { AwarenessSession.for(2) }

    it "increases number of active sessions for user" do
      expect do
        subject.join(session)
        subject.join(session2)
      end.to change { subject.session_ids.size }
               .by(2)
    end
  end
end
