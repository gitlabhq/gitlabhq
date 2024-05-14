# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:doctor:reset_encrypted_tokens', :silence_stdout, feature_category: :fleet_visibility do
  let(:model_names) { 'Project,Group' }
  let(:token_names) { 'runners_token' }

  let(:project_with_cipher_error) do
    create(:project, :allow_runner_registration_token).tap do |project|
      project.update_columns(runners_token_encrypted:
        '|rXs75DSHXPE9MGAIgyxcut8pZc72gaa/2ojU0GS1+R+cXNqkbUB13Vb5BaMwf47d98980fc1')
    end
  end

  before(:context) do
    Rake.application.rake_require 'tasks/gitlab/doctor/secrets'
  end

  before do
    stub_env('MODEL_NAMES', model_names)
    stub_env('TOKEN_NAMES', token_names)
  end

  subject(:run!) do
    run_rake_task('gitlab:doctor:reset_encrypted_tokens')
  end

  it 'properly parses parameters from the environment variables' do
    expect_next_instance_of(::Gitlab::Doctor::ResetTokens, anything,
      model_names: %w[Project Group],
      token_names: %w[runners_token],
      dry_run: true) do |service|
      expect(service).to receive(:run!).and_call_original
    end

    run!
  end

  it "doesn't do anything in DRY_RUN mode(default)" do
    expect do
      run!
    end.not_to change { project_with_cipher_error.reload.runners_token_encrypted }
  end

  it 'regenerates broken token if DRY_RUN is set to false' do
    stub_env('DRY_RUN', false)

    expect { project_with_cipher_error.runners_token }.to raise_error(OpenSSL::Cipher::CipherError)
    expect do
      run!
    end.to change { project_with_cipher_error.reload.runners_token_encrypted }

    expect { project_with_cipher_error.runners_token }.not_to raise_error
  end
end
