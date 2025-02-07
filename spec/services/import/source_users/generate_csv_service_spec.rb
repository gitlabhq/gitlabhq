# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsers::GenerateCsvService, feature_category: :importers do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:current_user) { namespace.owner }

  let_it_be(:user_pending_assignment) { create(:import_source_user, :pending_reassignment, namespace: namespace) }
  let_it_be(:user_awaiting_approval) { create(:import_source_user, :awaiting_approval, namespace: namespace) }
  let_it_be(:rejected_user) { create(:import_source_user, :rejected, namespace: namespace) }

  subject(:service) { described_class.new(namespace, current_user: current_user) }

  describe '#execute' do
    context 'when the user is a namespace owner', :aggregate_failures do
      it 'returns spreadsheet data' do
        result = service.execute

        expect(result).to be_success

        csv_data = CSV.parse(result.payload)

        expect(csv_data[0]).to match_array(described_class::COLUMN_MAPPING.keys)

        expect(csv_data[1..]).to match_array([
          [
            user_pending_assignment.source_hostname,
            user_pending_assignment.import_type,
            user_pending_assignment.source_user_identifier,
            user_pending_assignment.source_name,
            user_pending_assignment.source_username,
            '',
            ''
          ],
          [
            rejected_user.source_hostname,
            rejected_user.import_type,
            rejected_user.source_user_identifier,
            rejected_user.source_name,
            rejected_user.source_username,
            '',
            ''
          ]
        ])
      end

      it 'returns only data for this namespace' do
        other_source_user = create(:import_source_user)

        result = service.execute

        csv_data = CSV.parse(result.payload)
        source_user_identifiers = csv_data.pluck(2)

        expect(source_user_identifiers).not_to include(other_source_user.source_user_identifier)
      end

      it 'returns only data for Import::SourceUser records with a re-assignable status' do
        result = service.execute

        csv_data = CSV.parse(result.payload)

        source_user_identifiers = csv_data.pluck(2).drop(1)
        expect(source_user_identifiers).to match_array([
          user_pending_assignment.source_user_identifier,
          rejected_user.source_user_identifier
        ])
      end

      context 'and there is no data to return' do
        let(:namespace) { create(:namespace) }

        subject(:service) { described_class.new(namespace, current_user: namespace.owner) }

        it 'only returns the headers' do
          result = service.execute
          csv_data = CSV.parse(result.payload)

          expect(csv_data.size).to eq(1)
          expect(csv_data[0]).to match_array(described_class::COLUMN_MAPPING.keys)
        end
      end

      context 'when the generated file is over-sized' do
        before do
          stub_const('Import::SourceUsers::GenerateCsvService::FILESIZE_LIMIT', 1)
        end

        it 'truncates the output' do
          result = service.execute
          csv_data = CSV.parse(result.payload)

          # Only the headers and the first row are written.
          expect(csv_data.size).to eq(2)
        end
      end
    end

    context 'when current user does not have permission' do
      subject(:service) { described_class.new(namespace, current_user: create(:user)) }

      it 'returns error no permissions' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('You do not have permission to view import source users for this namespace')
      end
    end
  end
end
