# frozen_string_literal: true

RSpec.shared_examples 'iam service error response' do |reason:, message:|
  it 'returns an error response and logs the failure', :aggregate_failures do
    allow(Gitlab::AuthLogger).to receive(:error)

    result

    expect(result).to be_error
    expect(result.reason).to eq(reason)
    expect(result.message).to eq(message)
    expect(Gitlab::AuthLogger).to have_received(:error)
  end
end

RSpec.shared_examples 'iam service error response with user' do |reason:, message:|
  it 'returns an error response and logs the failure with user id', :aggregate_failures do
    allow(Gitlab::AuthLogger).to receive(:error)

    result

    expect(result).to be_error
    expect(result.reason).to eq(reason)
    expect(result.message).to eq(message)
    expect(Gitlab::AuthLogger).to have_received(:error)
      .with(hash_including(Labkit::Fields::GL_USER_ID => user.id))
  end
end

RSpec.shared_examples 'does not emit IAM consent audit event' do
  it 'does not emit an IAM consent audit event' do
    expect(::Gitlab::Audit::Auditor).not_to receive(:audit).with(
      hash_including(name: match(/iam_oauth_application/))
    )

    result
  end
end

RSpec.shared_examples 'does not create a consent record' do
  it 'does not create a consent record' do
    expect { result }.not_to change { Authn::OauthConsent.count }
  end
end

RSpec.shared_examples 'iam consent persistence failure handling' do
  it 'returns an error, logs the failure, and tracks the exception', :aggregate_failures do
    expect(Gitlab::ErrorTracking).to receive(:track_exception).with(a_kind_of(ActiveRecord::ActiveRecordError))
    expect(Gitlab::AuthLogger).to receive(:error).with(
      hash_including(
        message: log_message,
        reason: 'persistence_error',
        Labkit::Fields::GL_USER_ID => user.id
      )
    )

    expect(result).to be_error
    expect(result.reason).to eq(:consent_record_invalid)
  end

  it_behaves_like 'does not create a consent record'
  include_examples 'does not emit IAM consent audit event'
end
