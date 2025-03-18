# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsers::BulkReassignFromCsvService, feature_category: :importers do
  let_it_be_with_reload(:user) { create(:user, :public_email, username: 'alice-gl', email: 'alice@example.com') }
  let_it_be(:author) { create(:user, username: 'csv_author') }
  let_it_be(:group) { create(:group, owners: author) }
  # The upload is destroyed after each run, so we can't use `let_it_be`
  let(:upload) { create(:upload, :with_file) }

  let(:username) { '' }
  let(:email) { '' }
  let(:csv_content) do
    <<~CSV
      Source host,Import type,Source user identifier,Source user name,Source username,GitLab username,GitLab public email
      https://github.com,github,alice_1,Alice Alison,alice,#{username},#{email}
    CSV
  end

  let(:service) { described_class.new(author, group, upload) }

  describe '#async_execute' do
    subject(:schedule_worker) { service.async_execute }

    before do
      allow_next_instance_of(CarrierWave::SanitizedFile) do |file|
        allow(file).to receive(:read).and_return(csv_content)
      end
    end

    it 'schedules the worker' do
      expect(Import::UserMapping::AssignmentFromCsvWorker).to receive(:perform_async)

      schedule_worker
    end
  end

  describe '#execute', :aggregate_failures do
    let_it_be_with_reload(:source_user) do
      create(:import_source_user, :pending_reassignment, namespace: group, source_user_identifier: 'alice_1')
    end

    let(:import_source_users) do
      [
        source_user
      ]
    end

    subject(:execute_service) { service.execute }

    before do
      allow_next_instance_of(CarrierWave::SanitizedFile) do |file|
        allow(file).to receive(:read).and_return(csv_content)
      end
    end

    context 'when file format is valid' do
      it { expect(execute_service).to be_success }

      context 'when username and email are both provided' do
        let(:username) { 'alice-gl' }
        let(:email) { 'alice@example.com' }

        it 'matches the source user' do
          expect { execute_service }
            .to change { source_user.reload.reassign_to_user }.from(nil).to(user)
        end
      end

      context 'when only the email is provided' do
        let(:email) { 'alice@example.com' }

        it 'matches the source user' do
          expect { execute_service }
            .to change { source_user.reload.reassign_to_user }.from(nil).to(user)
        end
      end

      context 'when only the username is provided' do
        let(:username) { 'alice-gl' }

        it 'matches the source user' do
          expect { execute_service }
            .to change { source_user.reload.reassign_to_user }.from(nil).to(user)
        end
      end

      context 'when neither username nor email are provided' do
        let(:username) { '' }
        let(:email) { '' }

        it 'counts the skipped row' do
          result = nil
          expect { result = execute_service }
            .to not_change { source_user.reload.reassign_to_user }

          stats = result.payload[:stats]
          expect(stats[:skipped]).to eq(1)
        end
      end

      context 'when provided details do not match a user' do
        let(:username) { 'some-unknown' }

        it 'does not match the source user' do
          result = nil
          expect { result = execute_service }
            .to not_change { source_user.reload.reassign_to_user }

          errors = result.payload[:failures_csv_data]
          expect(errors).to match(/alice_1,.*,No matching user for provided information./)
        end
      end

      context 'when the requested reassignment is already pending' do
        let(:username) { 'alice-gl' }

        before do
          source_user.update!(status: 1, reassign_to_user: user, reassignment_token: SecureRandom.hex)
        end

        it 'treats it as a match' do
          result = execute_service

          stats = result.payload[:stats]
          expect(stats).to match(matched: 1, failed: 0, skipped: 0)
        end
      end

      context 'when a different reassignment is already pending' do
        let(:username) { 'alice-gl' }

        before do
          source_user.update!(status: 1, reassign_to_user: create(:user), reassignment_token: SecureRandom.hex)
        end

        it 'treats it as a failure' do
          result = execute_service

          stats = result.payload[:stats]
          expect(stats).to match(matched: 0, failed: 1, skipped: 0)
        end
      end

      context 'when the reassignment service returns an error' do
        before do
          allow_next_instance_of(::Import::SourceUsers::ReassignService) do |reassign_service|
            allow(reassign_service).to receive(:execute).and_return(ServiceResponse.error(message: 'Test error'))
          end
        end

        let(:username) { 'alice-gl' }

        it 'is reflected in the results CSV' do
          result = execute_service

          errors = result.payload[:failures_csv_data]
          expect(errors).to match(/alice_1,.*,Test error/)
        end
      end

      context 'when providing a private email in the CSV' do
        before do
          create(:email, :confirmed, user: user, email: email)
        end

        let(:email) { 'alice-secret@example.com' }

        it 'only matches by public email' do
          result = nil
          expect { result = execute_service }
            .to not_change { source_user.reload.reassign_to_user }

          errors = result.payload[:failures_csv_data]
          expect(errors).to match(/alice_1,.*,No matching user for provided information./)
        end

        context 'and the author is an admin' do
          before do
            allow(author).to receive(:can_admin_all_resources?).and_return(true)
          end

          it 'matches by any confirmed email' do
            expect { execute_service }
              .to change { source_user.reload.reassign_to_user }
              .from(nil).to(user)
          end
        end
      end
    end

    context 'when the CSV is missing headers' do
      let(:csv_content) do
        <<~CSV
          Source host,Import type,Source user name,Source username,GitLab username
          https://github.com,github,Alice Alison,alice,alice-gl
        CSV
      end

      it 'records the error in the response object' do
        response = execute_service

        expect(response.success?).to be_falsey
        expect(response.message).to eq(:invalid_csv_format)
      end
    end
  end
end
