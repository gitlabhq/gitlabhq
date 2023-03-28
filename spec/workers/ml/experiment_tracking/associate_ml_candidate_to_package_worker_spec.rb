# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::ExperimentTracking::AssociateMlCandidateToPackageWorker, feature_category: :mlops do
  describe '.handle_event' do
    let_it_be(:candidate) { create(:ml_candidates) }
    let_it_be(:package) do
      create(
        :generic_package,
        project: candidate.project,
        name: candidate.package_name,
        version: candidate.package_version
      )
    end

    let(:package_name) { package.name }
    let(:data) do
      {
        project_id: package.project_id,
        id: package.id,
        name: package_name,
        version: package.version,
        package_type: package.package_type
      }
    end

    let(:package_created_event) { Packages::PackageCreatedEvent.new(data: data) }

    it_behaves_like 'subscribes to event' do
      let(:event) { package_created_event }
    end

    context 'when package name matches ml_candidate_{id}' do
      context 'when candidate with id exists' do
        it 'associates candidate to package' do
          consume_event(subscriber: described_class, event: package_created_event)

          expect(candidate.reload.package).to eq(package)
        end
      end

      context 'when no candidate with id exists' do
        let(:package_name) { "ml_candidate_#{non_existing_record_iid}" }

        it 'does not associate candidate' do
          consume_event(subscriber: described_class, event: package_created_event)

          expect(candidate.reload.package).to be_nil
        end
      end
    end

    context 'when package name does not match' do
      let(:package_name) { non_existing_record_iid.to_s }

      it 'does not associate candidate' do
        consume_event(subscriber: described_class, event: package_created_event)

        expect(candidate.reload.package_id).to be_nil
      end
    end

    context 'when package is deleted before event is called' do
      before do
        package.delete
      end

      it 'does not associate candidate' do
        consume_event(subscriber: described_class, event: package_created_event)

        expect(candidate.reload.package_id).to be_nil
      end
    end
  end

  describe '#handles_event?' do
    using RSpec::Parameterized::TableSyntax

    let(:event) do
      Packages::PackageCreatedEvent.new(
        data: {
          project_id: 1,
          id: 1,
          name: package_name,
          version: '',
          package_type: package_type
        }
      )
    end

    subject { described_class.handles_event?(event) }

    where(:package_name, :package_type, :handles_event) do
      'ml_candidate_1234' | 'generic' | true
      'ml_candidate_1234' | 'maven' | false
      '1234' | 'generic' | false
      'ml_candidate_' | 'generic' | false
      'blah' | 'generic' | false
    end

    with_them do
      it { is_expected.to eq(handles_event) }
    end
  end
end
