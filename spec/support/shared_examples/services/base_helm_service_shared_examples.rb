# frozen_string_literal: true

shared_examples 'logs kubernetes errors' do
  let(:error_hash) do
    {
      service: service.class.name,
      app_id: application.id,
      project_ids: application.cluster.project_ids,
      group_ids: [],
      error_code: error_code
    }
  end

  it 'logs into kubernetes.log and Sentry' do
    expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
      error,
      hash_including(error_hash)
    )

    service.execute
  end
end
