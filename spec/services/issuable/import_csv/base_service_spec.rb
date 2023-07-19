# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::ImportCsv::BaseService, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:csv_io) { double }

  let(:importer_klass) do
    Class.new(described_class) do
      def email_results_to_user
        # no-op
      end
    end
  end

  let(:service) do
    uploader = FileUploader.new(project)
    uploader.store!(file)

    importer_klass.new(user, project, uploader)
  end

  subject { service.execute }

  describe '#preprocess_milestones' do
    let(:utility_class) { ImportCsv::PreprocessMilestonesService }
    let(:file) { fixture_file_upload('spec/fixtures/csv_missing_milestones.csv') }
    let(:mocked_object) { double }

    before do
      allow(service).to receive(:create_object).and_return(mocked_object)
      allow(mocked_object).to receive(:persisted?).and_return(true)
    end

    context 'with csv that has milestone heading' do
      before do
        allow(utility_class).to receive(:new).and_return(utility_class)
        allow(utility_class).to receive(:execute).and_return(ServiceResponse.success)
      end

      it 'calls PreprocessMilestonesService' do
        subject
        expect(utility_class).to have_received(:new)
      end

      it 'calls PreprocessMilestonesService with unique milestone titles' do
        subject
        expect(utility_class).to have_received(:new).with(user, project, %w[15.10 10.1])
        expect(utility_class).to have_received(:execute)
      end
    end

    context 'with csv that does not have milestone heading' do
      let(:file) { fixture_file_upload('spec/fixtures/work_items_valid_types.csv') }

      before do
        allow(utility_class).to receive(:new).and_return(utility_class)
      end

      it 'does not call PreprocessMilestonesService' do
        subject
        expect(utility_class).not_to have_received(:new)
      end
    end

    context 'when one or more milestones do not exist' do
      it 'returns the expected error in results payload' do
        results = subject

        expect(results[:success]).to eq(0)
        expect(results[:preprocess_errors]).to match({
          milestone_errors: { missing: { header: 'Milestone', titles: %w[15.10 10.1] } }
        })
      end
    end

    context 'when all milestones exist' do
      let!(:group_milestone) { create(:milestone, group: group, title: '10.1') }
      let!(:project_milestone) { create(:milestone, project: project, title: '15.10') }

      it 'returns a successful response' do
        results = subject

        expect(results[:preprocess_errors]).to be_empty
        expect(results[:success]).to eq(4)
      end
    end
  end
end
