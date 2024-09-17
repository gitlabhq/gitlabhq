# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::SpamAbuseEventsWorker, :clean_gitlab_redis_shared_state, feature_category: :instance_resiliency do
  let(:worker) { described_class.new }
  let_it_be(:user) { create(:user) }

  let(:params) do
    {
      user_id: user.id,
      title: 'Test title',
      description: 'Test description',
      source_ip: '1.2.3.4',
      user_agent: 'fake-user-agent',
      noteable_type: 'Issue',
      verdict: 'BLOCK_USER'
    }
  end

  shared_examples 'creates an abuse event with the correct data' do
    it do
      expect { worker.perform(params) }.to change { AntiAbuse::Event.count }.from(0).to(1)
      expect(AntiAbuse::Event.last.attributes).to include({
        abuse_report_id: report_id,
        category: "spam",
        metadata: params.except(:user_id),
        source: "spamcheck",
        user_id: params[:user_id]
      }.deep_stringify_keys)
    end
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [params] }
  end

  context "when the user does not exist" do
    let(:log_payload) { { 'message' => 'User not found.', 'user_id' => user.id } }

    before do
      allow(User).to receive(:find_by_id).with(user.id).and_return(nil)
    end

    it 'logs an error' do
      expect(Sidekiq.logger).to receive(:info).with(hash_including(log_payload))

      expect { worker.perform(params) }.not_to raise_exception
    end

    it 'does not report the user' do
      expect(described_class).not_to receive(:report_user).with(user.id)

      worker.perform(params)
    end
  end

  context "when the user exists" do
    context 'and there is an existing abuse report' do
      let_it_be(:abuse_report) do
        create(:abuse_report, user: user, reporter: Users::Internal.security_bot, message: 'Test report')
      end

      it_behaves_like 'creates an abuse event with the correct data' do
        let(:report_id) { abuse_report.id }
      end
    end

    context 'and there is no existing abuse report' do
      it 'creates an abuse report with the correct data' do
        expect { worker.perform(params) }.to change { AbuseReport.count }.from(0).to(1)
        expect(AbuseReport.last.attributes).to include({
          reporter_id: Users::Internal.security_bot.id,
          user_id: user.id,
          category: "spam",
          message: "User reported for abuse based on spam verdict"
        }.stringify_keys)
      end

      it_behaves_like 'creates an abuse event with the correct data' do
        let(:report_id) { AbuseReport.last.attributes["id"] }
      end
    end
  end
end
