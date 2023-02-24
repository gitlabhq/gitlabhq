# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ImportCsvService, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user, username: 'csv_author') }
  let(:file) { fixture_file_upload('spec/fixtures/work_items_valid.csv') }
  let(:service) do
    uploader = FileUploader.new(project)
    uploader.store!(file)

    described_class.new(user, project, uploader)
  end

  let_it_be(:issue_type) { ::WorkItems::Type.default_issue_type }

  let(:work_items) { ::WorkItems::WorkItemsFinder.new(user, project: project).execute }
  let(:email_method) { :import_work_items_csv_email }

  subject { service.execute }

  describe '#execute' do
    context 'when user has permission' do
      before do
        project.add_guest(user)
      end

      it_behaves_like 'importer with email notification'

      context 'when file is valid' do
        it 'creates the expected number of work items' do
          expect { subject }.to change { work_items.count }.by 2
        end

        describe 'imported work item details' do
          it 'sets work item attributes' do
            result = subject

            expect(work_items.reload).to contain_exactly(
              have_attributes(
                title: '馬のスモモモモモモモモ',
                work_item_type_id: issue_type.id
              ),
              have_attributes(
                title: 'Do this task',
                work_item_type_id: issue_type.id
              )
            )

            expect(result[:success]).to eq(2)
            expect(result[:error_lines]).to eq([])
            expect(result[:parse_error]).to eq(false)
          end

          it 'defaults all work items to issue type' do
            subject

            expect(work_items.reload).to all(have_attributes(work_item_type: issue_type))
          end
        end
      end

      context 'when file is missing necessary headers' do
        let(:file) { fixture_file_upload('spec/fixtures/work_items_missing_header.csv') }

        it 'creates no records' do
          result = subject

          expect(result[:success]).to eq(0)
          expect(result[:error_lines]).to eq([1])
          expect(result[:parse_error]).to eq(true)
        end

        it 'creates no work items' do
          expect { subject }.not_to change { work_items.count }
        end
      end

      context 'when import_export_work_items_csv feature flag is off' do
        before do
          stub_feature_flags(import_export_work_items_csv: false)
        end

        it 'returns an error' do
          expect { subject }.to raise_error(/This feature is currently behind a feature flag and it is not available./)
        end
      end
    end

    context 'when user does not have permission' do
      it 'errors on those lines', :aggregate_failures do
        result = subject

        expect(result[:success]).to eq(0)
        expect(result[:error_lines]).to match_array([2, 3])
        expect(result[:parse_error]).to eq(false)
      end
    end
  end

  context 'when user does not have permission' do
    it 'errors on those lines', :aggregate_failures do
      result = subject

      expect(result[:success]).to eq(0)
      expect(result[:error_lines]).to eq([2, 3])
      expect(result[:parse_error]).to eq(false)
    end
  end
end
