# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ChatTeam, feature_category: :groups_and_projects do
  let_it_be(:chat_team, freeze: false) { create(:chat_team) }

  subject { chat_team }

  # Associations
  it { is_expected.to belong_to(:namespace) }

  # Validations
  it { is_expected.to validate_uniqueness_of(:namespace) }

  # Fields
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:team_id) }

  describe '#remove_mattermost_team' do
    let(:user) { build_stubbed(:user) }

    context 'when Mattermost team deletion succeeds' do
      it 'calls destroy on the Mattermost team' do
        expect_next_instance_of(::Mattermost::Team) do |instance|
          expect(instance).to receive(:destroy).with(team_id: chat_team.team_id)
        end

        chat_team.remove_mattermost_team(user)
      end
    end

    context 'when a Mattermost::ClientError is raised' do
      before do
        allow_next_instance_of(::Mattermost::Team) do |instance|
          allow(instance).to receive(:destroy).and_raise(::Mattermost::ClientError, 'team not found')
        end
      end

      it 'logs a warning and does not re-raise' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          hash_including(
            message: "Mattermost team deletion failed, proceeding with group deletion",
            team_id: chat_team.team_id,
            Labkit::Fields::ERROR_TYPE => 'Mattermost::ClientError'
          )
        )

        expect { chat_team.remove_mattermost_team(user) }.not_to raise_error
      end
    end

    context 'when a Mattermost::ConnectionError is raised' do
      before do
        stub_const('Mattermost::ConnectionError', Class.new(::Mattermost::Error))
        allow_next_instance_of(::Mattermost::Team) do |instance|
          allow(instance).to receive(:destroy).and_raise(::Mattermost::ConnectionError, 'connection refused')
        end
      end

      it 'logs a warning and does not re-raise' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          hash_including(
            message: "Mattermost team deletion failed, proceeding with group deletion",
            team_id: chat_team.team_id,
            Labkit::Fields::ERROR_TYPE => 'Mattermost::ConnectionError'
          )
        )

        expect { chat_team.remove_mattermost_team(user) }.not_to raise_error
      end
    end

    context 'when a Mattermost::NoSessionError is raised' do
      before do
        stub_const('Mattermost::NoSessionError', Class.new(::Mattermost::Error))
        allow_next_instance_of(::Mattermost::Team) do |instance|
          allow(instance).to receive(:destroy).and_raise(::Mattermost::NoSessionError)
        end
      end

      it 'logs a warning and does not re-raise' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          hash_including(
            message: "Mattermost team deletion failed, proceeding with group deletion",
            team_id: chat_team.team_id,
            Labkit::Fields::ERROR_TYPE => 'Mattermost::NoSessionError'
          )
        )

        expect { chat_team.remove_mattermost_team(user) }.not_to raise_error
      end
    end

    context 'when a Gitlab::HTTP::BlockedUrlError is raised (e.g. Mattermost URL is blocked by SSRF protection)' do
      before do
        allow_next_instance_of(::Mattermost::Team) do |instance|
          allow(instance).to receive(:destroy)
            .and_raise(Gitlab::HTTP_V2::BlockedUrlError, 'URL is blocked: Only allowed schemes are https')
        end
      end

      it 'logs a warning and does not re-raise' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          hash_including(
            message: "Mattermost team deletion failed, proceeding with group deletion",
            team_id: chat_team.team_id,
            Labkit::Fields::ERROR_TYPE => 'Gitlab::HTTP_V2::BlockedUrlError'
          )
        )

        expect { chat_team.remove_mattermost_team(user) }.not_to raise_error
      end
    end
  end
end
