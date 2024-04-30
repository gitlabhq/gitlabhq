# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Doctor::ResetTokens, feature_category: :fleet_visibility do
  let(:logger) { instance_double('Logger') }
  let(:model_names) { %w[Project Group] }
  let(:token_names) { %w[runners_token] }
  let(:dry_run) { false }
  let(:doctor) { described_class.new(logger, model_names: model_names, token_names: token_names, dry_run: dry_run) }

  let_it_be(:functional_project) { create(:project).tap(&:runners_token) }
  let_it_be(:functional_group) { create(:group).tap(&:runners_token) }

  let(:broken_project) do
    create(:project, :allow_runner_registration_token).tap do |project|
      project.update_columns(runners_token_encrypted: 'aaa')
    end
  end

  let(:project_with_cipher_error) do
    create(:project, :allow_runner_registration_token).tap do |project|
      project.update_columns(
        runners_token_encrypted: '|rXs75DSHXPE9MGAIgyxcut8pZc72gaa/2ojU0GS1+R+cXNqkbUB13Vb5BaMwf47d98980fc1')
    end
  end

  let(:broken_group) { create(:group, :allow_runner_registration_token, runners_token_encrypted: 'aaa') }

  subject(:run!) do
    expect(logger).to receive(:info).with(
      "Resetting #{token_names.join(', ')} on #{model_names.join(', ')} if they can not be read"
    )
    expect(logger).to receive(:info).with('Done!')
    doctor.run!
  end

  before do
    allow(logger).to receive(:info).with(%r{Checked \d/\d Projects})
    allow(logger).to receive(:info).with(%r{Checked \d Projects})
    allow(logger).to receive(:info).with(%r{Checked \d/\d Groups})
    allow(logger).to receive(:info).with(%r{Checked \d Groups})
  end

  it 'fixes broken project and not the functional project' do
    expect(logger).to receive(:debug).with("> Fix Project[#{broken_project.id}].runners_token")

    expect { run! }.to change { broken_project.reload.runners_token_encrypted }.from('aaa')
      .and not_change { functional_project.reload.runners_token_encrypted }
    expect { broken_project.runners_token }.not_to raise_error
  end

  it 'fixes project with cipher error' do
    expect { project_with_cipher_error.runners_token }.to raise_error(OpenSSL::Cipher::CipherError)
    expect(logger).to receive(:debug).with("> Fix Project[#{project_with_cipher_error.id}].runners_token")

    expect { run! }.to change { project_with_cipher_error.reload.runners_token_encrypted }
    expect { project_with_cipher_error.runners_token }.not_to raise_error
  end

  it 'fixes broken group and not the functional group' do
    expect(logger).to receive(:debug).with("> Fix Group[#{broken_group.id}].runners_token")

    expect { run! }.to change { broken_group.reload.runners_token_encrypted }.from('aaa')
      .and not_change { functional_group.reload.runners_token_encrypted }

    expect { broken_group.runners_token }.not_to raise_error
  end

  context 'when one model specified' do
    let(:model_names) { %w[Project] }

    it 'fixes broken project' do
      expect(logger).to receive(:debug).with("> Fix Project[#{broken_project.id}].runners_token")

      expect { run! }.to change { broken_project.reload.runners_token_encrypted }.from('aaa')
      expect { broken_project.runners_token }.not_to raise_error
    end

    it 'does not fix other models' do
      expect { run! }.not_to change { broken_group.reload.runners_token_encrypted }.from('aaa')
    end
  end

  context 'when non-existing token field is given' do
    let(:token_names) { %w[nonexisting_token] }

    it 'does not fix anything' do
      expect { run! }.not_to change { broken_project.reload.runners_token_encrypted }.from('aaa')
    end
  end

  context 'when executing in a dry-run mode' do
    let(:dry_run) { true }

    it 'prints info about fixed project, but does not actually do anything' do
      expect(logger).to receive(:info).with('Executing in DRY RUN mode, no records will actually be updated')
      expect(logger).to receive(:debug).with("> Fix Project[#{broken_project.id}].runners_token")

      expect { run! }.not_to change { broken_project.reload.runners_token_encrypted }.from('aaa')
      expect { broken_project.runners_token }.to raise_error(TypeError)
    end
  end

  it 'prints progress along the way' do
    stub_const('Gitlab::Doctor::ResetTokens::PRINT_PROGRESS_EVERY', 1)

    broken_project
    project_with_cipher_error

    expect(logger).to receive(:info).with(
      "Resetting #{token_names.join(', ')} on #{model_names.join(', ')} if they can not be read"
    )
    expect(logger).to receive(:info).with('Checked 1/3 Projects')
    expect(logger).to receive(:debug).with("> Fix Project[#{broken_project.id}].runners_token")
    expect(logger).to receive(:info).with('Checked 2/3 Projects')
    expect(logger).to receive(:debug).with("> Fix Project[#{project_with_cipher_error.id}].runners_token")
    expect(logger).to receive(:info).with('Checked 3/3 Projects')
    expect(logger).to receive(:info).with('Done!')

    doctor.run!
  end

  it "prints 'Something went wrong' error when encounters unexpected exception, but continues" do
    broken_project
    project_with_cipher_error

    expect(logger).to receive(:debug).with(
      "> Something went wrong for Project[#{broken_project.id}].runners_token: Error message")
    expect(logger).to receive(:debug).with("> Fix Project[#{project_with_cipher_error.id}].runners_token")

    expect(broken_project).to receive(:runners_token).and_raise("Error message")
    expect(Project).to receive(:find_each).and_return([broken_project, project_with_cipher_error].each)

    expect { run! }.to not_change { broken_project.reload.runners_token_encrypted }.from('aaa')
      .and change { project_with_cipher_error.reload.runners_token_encrypted }
  end
end
