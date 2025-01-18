# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AfterImportWorker, feature_category: :importers do
  subject { worker.perform(project.id) }

  let(:worker) { described_class.new }
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:sha) { project.commit.sha }
  let(:housekeeping_service) { double(:housekeeping_service) }

  describe '#execute' do
    before do
      allow(::Repositories::HousekeepingService)
        .to receive(:new).with(project).and_return(housekeeping_service)

      allow(housekeeping_service)
        .to receive(:execute).and_yield

      allow(housekeeping_service).to receive(:increment!)
    end

    it 'performs housekeeping' do
      subject

      expect(housekeeping_service).to have_received(:execute)
    end

    context 'with some refs in refs/pull/**/*' do
      before do
        repository.write_ref('refs/pull/1/head', sha)
        repository.write_ref('refs/pull/1/merge', sha)

        subject
      end

      it 'removes refs/pull/**/*' do
        expect(repository.list_refs(['refs/pull/'])).to be_empty
      end
    end

    Repository::RESERVED_REFS_NAMES.each do |name|
      context "with a ref in refs/#{name}/tmp" do
        before do
          repository.write_ref("refs/#{name}/tmp", sha)

          subject
        end

        it "does not remove refs/#{name}/tmp" do
          expect(repository.list_refs(["refs/#{name}/tmp"]).length).to be(1)
        end
      end
    end

    context 'when after import action throw non-retriable exception' do
      let(:exception) { StandardError.new('after import error') }

      before do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:delete_all_refs_except)
          .and_raise(exception)
        end
      end

      it 'throws after import error' do
        expect { subject }.to raise_exception('after import error')
      end
    end

    context 'when housekeeping service lease is taken' do
      let(:exception) { ::Repositories::HousekeepingService::LeaseTaken.new }

      it 'logs the error message' do
        allow_next_instance_of(::Repositories::HousekeepingService) do |instance|
          expect(instance).to receive(:execute).and_raise(exception)
        end

        expect(::Import::Framework::Logger).to receive(:info).with(
          {
            message: 'Project housekeeping failed',
            project_full_path: project.full_path,
            project_id: project.id,
            'exception.message' => exception.to_s
          }).and_call_original

        subject
      end
    end

    context 'when after import action throw retriable exception one time' do
      let(:exception) { GRPC::DeadlineExceeded.new }

      it 'removes refs/pull/**/*' do
        subject

        expect(repository.list_refs(['refs/pull/'])).to be_empty
      end

      it 'records the failures in the database', :aggregate_failures do
        expect_next_instance_of(Repository) do |repository|
          expect(repository).to receive(:delete_all_refs_except).and_raise(exception)
          expect(repository).to receive(:delete_all_refs_except).and_call_original
        end

        subject

        import_failure = ImportFailure.last

        expect(import_failure.source).to eq('delete_all_refs')
        expect(import_failure.project_id).to eq(project.id)
        expect(import_failure.relation_key).to be_nil
        expect(import_failure.relation_index).to be_nil
        expect(import_failure.exception_class).to eq('GRPC::DeadlineExceeded')
        expect(import_failure.exception_message).to be_present
        expect(import_failure.correlation_id_value).not_to be_empty
      end
    end
  end
end
