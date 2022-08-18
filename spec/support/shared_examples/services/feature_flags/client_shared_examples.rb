# frozen_string_literal: true

RSpec.shared_examples_for 'update feature flag client' do
  let!(:client) { create(:operations_feature_flags_client, project: project) }

  it 'updates last feature flag updated at' do
    freeze_time do
      expect { subject }.to change { client.reload.last_feature_flag_updated_at }.from(nil).to(Time.current)
    end
  end
end

RSpec.shared_examples_for 'does not update feature flag client' do
  let!(:client) { create(:operations_feature_flags_client, project: project) }

  it 'does not update last feature flag updated at' do
    expect { subject }.not_to change { client.reload.last_feature_flag_updated_at }
  end
end
