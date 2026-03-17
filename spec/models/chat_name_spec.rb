# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ChatName, feature_category: :integrations do
  let_it_be_with_reload(:chat_name) { create(:chat_name) }

  subject { chat_name }

  it { is_expected.to belong_to(:user) }

  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:team_id) }
  it { is_expected.to validate_presence_of(:chat_id) }
  it { is_expected.to validate_length_of(:token).is_at_most(described_class::MAX_PARAM_LENGTH) }
  it { is_expected.to validate_length_of(:team_id).is_at_most(described_class::MAX_PARAM_LENGTH) }
  it { is_expected.to validate_length_of(:team_domain).is_at_most(described_class::MAX_PARAM_LENGTH) }
  it { is_expected.to validate_length_of(:chat_id).is_at_most(described_class::MAX_PARAM_LENGTH) }
  it { is_expected.to validate_length_of(:chat_name).is_at_most(described_class::MAX_PARAM_LENGTH) }

  it { is_expected.to validate_uniqueness_of(:chat_id).scoped_to(:team_id) }

  it_behaves_like 'encrypted attribute', :token, :db_key_base_32 do
    let(:record) { chat_name }
  end

  describe '.for_team_and_chat_ids' do
    let_it_be(:team_id) { 'T0123TEAM' }
    let_it_be(:user_a) { create(:user) }
    let_it_be(:user_b) { create(:user) }
    let_it_be(:cn_a) { create(:chat_name, user: user_a, team_id: team_id, chat_id: 'U0001') }
    let_it_be(:cn_b) { create(:chat_name, user: user_b, team_id: team_id, chat_id: 'U0002') }
    let_it_be(:cn_other_team) { create(:chat_name, team_id: 'T_OTHER', chat_id: 'U0001') }

    it 'returns only records matching the team and given chat IDs' do
      expect(described_class.for_team_and_chat_ids(team_id, %w[U0001 U0002]))
        .to contain_exactly(cn_a, cn_b)
    end

    it 'excludes chat IDs not in the given list' do
      expect(described_class.for_team_and_chat_ids(team_id, ['U0001']))
        .to contain_exactly(cn_a)
    end
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

    it 'updates last_used_at if it was not recently updated' do
      allow_next_instance_of(Gitlab::ExclusiveLease) do |lease|
        allow(lease).to receive(:try_obtain).and_return('successful_lease_guid')
      end

      subject.update_last_used_at

      new_time = ChatName::LAST_USED_AT_INTERVAL.from_now + 5.minutes

      travel_to(new_time) do
        subject.update_last_used_at
      end

      expect(subject.last_used_at).to be_like_time(new_time)
    end
  end

  it_behaves_like 'it has loose foreign keys' do
    let(:factory_name) { :chat_name }
  end
end
