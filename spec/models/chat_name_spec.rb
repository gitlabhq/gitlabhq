# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ChatName do
  let_it_be(:chat_name) { create(:chat_name) }

  subject { chat_name }

  it { is_expected.to belong_to(:integration) }
  it { is_expected.to belong_to(:user) }

  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:integration) }
  it { is_expected.to validate_presence_of(:team_id) }
  it { is_expected.to validate_presence_of(:chat_id) }

  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:service_id) }
  it { is_expected.to validate_uniqueness_of(:chat_id).scoped_to(:service_id, :team_id) }

  it 'is removed when the project is deleted' do
    expect { subject.reload.integration.project.delete }.to change { ChatName.count }.by(-1)

    expect(ChatName.where(id: subject.id)).not_to exist
  end

  describe '#update_last_used_at', :clean_gitlab_redis_shared_state do
    it 'updates the last_used_at timestamp' do
      expect(subject.last_used_at).to be_nil

      subject.update_last_used_at

      expect(subject.last_used_at).to be_present
    end

    it 'does not update last_used_at if it was recently updated' do
      subject.update_last_used_at

      time = subject.last_used_at

      subject.update_last_used_at

      expect(subject.last_used_at).to eq(time)
    end
  end
end
