# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Base::RelationObjectSaver, feature_category: :importers do
  let(:project) { create(:project) }
  let(:relation_object) { build(:issue, project: project) }
  let(:relation_definition) { {} }
  let(:importable) { project }
  let(:relation_key) { 'issues' }

  subject(:saver) do
    described_class.new(
      relation_object: relation_object,
      relation_key: relation_key,
      relation_definition: relation_definition,
      importable: importable
    )
  end

  describe '#save' do
    before do
      expect(relation_object).to receive(:save!).and_call_original
    end

    it 'saves relation object' do
      expect { saver.execute }.to change(project.issues, :count).by(1)
    end

    context 'when subrelation collection is present' do
      let(:notes) { build_list(:note, 2, project: project, importing: true) }
      let(:relation_object) { build(:issue, project: project, notes: notes) }
      let(:relation_definition) { { 'notes' => {} } }

      it 'saves relation object with subrelations' do
        expect(relation_object.notes).to receive(:<<).and_call_original
        expect(relation_object).to receive(:save).and_call_original

        saver.execute

        issue = project.issues.last
        expect(issue.notes.count).to eq(2)
      end
    end

    context 'when subrelation is not a collection' do
      let(:sentry_issue) { build(:sentry_issue, importing: true) }
      let(:relation_object) { build(:issue, project: project, sentry_issue: sentry_issue) }
      let(:relation_definition) { { 'sentry_issue' => {} } }

      it 'saves subrelation as part of the relation object itself' do
        expect(relation_object.notes).not_to receive(:<<)

        saver.execute

        issue = project.issues.last
        expect(issue.sentry_issue.persisted?).to eq(true)
      end
    end

    context 'when some subrelations are invalid' do
      let(:note) { build(:note, project: project, importing: true) }
      let(:invalid_note) { build(:note) }
      let(:relation_object) { build(:issue, project: project, notes: [note, invalid_note]) }
      let(:relation_definition) { { 'notes' => {} } }

      it 'saves valid subrelations and logs invalid subrelation' do
        expect(relation_object.notes).to receive(:<<).twice.and_call_original
        expect(relation_object).to receive(:save).and_call_original

        saver.execute

        issue = project.issues.last

        expect(invalid_note.persisted?).to eq(false)
        expect(issue.notes.count).to eq(1)
      end

      context 'when invalid subrelation can still be persisted' do
        let(:relation_key) { 'merge_requests' }
        let(:relation_definition) { { 'approvals' => {} } }
        let(:approval_1) { build(:approval, merge_request_id: nil, user: create(:user)) }
        let(:approval_2) { build(:approval, merge_request_id: nil, user: create(:user)) }
        let(:relation_object) { build(:merge_request, source_project: project, target_project: project, approvals: [approval_1, approval_2]) }

        it 'saves the subrelation' do
          expect(approval_1.valid?).to eq(false)

          saver.execute

          expect(project.merge_requests.first.approvals.count).to eq(2)
          expect(project.merge_requests.first.approvals.first.persisted?).to eq(true)
        end
      end

      context 'when importable is group' do
        let(:relation_key) { 'labels' }
        let(:relation_definition) { { 'priorities' => {} } }
        let(:importable) { create(:group) }
        let(:valid_priorities) { [build(:label_priority, importing: true)] }
        let(:invalid_priority) { build(:label_priority, priority: -1) }
        let(:relation_object) { build(:group_label, group: importable, title: 'test', priorities: valid_priorities + [invalid_priority]) }

        it 'saves relation without invalid subrelations' do
          saver.execute

          expect(importable.labels.last.priorities.count).to eq(1)
        end
      end
    end

    context 'when database timeout (ActiveRecord::QueryCanceled) occurs during batch processing' do
      let(:notes) { build_list(:note, 10, project: project, importing: true) }
      let(:relation_object) { build(:issue, project: project, notes: notes) }
      let(:relation_definition) { { 'notes' => {} } }

      before do
        stub_feature_flags(import_rescue_query_canceled: true)
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(import_rescue_query_canceled: false)
        end

        it 're-raises the exception without retrying' do
          allow(saver).to receive(:save_valid_records).and_raise(ActiveRecord::QueryCanceled)

          expect { saver.execute }.to raise_error(ActiveRecord::QueryCanceled)
          expect(saver).not_to receive(:process_with_smaller_batch_size)
        end
      end

      context 'when maximum exception rescue count is exceeded' do
        it 're-raises the exception after MAX_EXCEPTION_RESCUE_COUNT attempts' do
          allow(saver).to receive(:save_valid_records).and_raise(ActiveRecord::QueryCanceled)

          saver.instance_variable_set(:@exceptions_rescued, described_class::MAX_EXCEPTION_RESCUE_COUNT - 1)

          expect { saver.execute }.to raise_error(ActiveRecord::QueryCanceled)
          expect(saver.instance_variable_get(:@exceptions_rescued)).to eq(described_class::MAX_EXCEPTION_RESCUE_COUNT)
        end

        it 'increments exception counter on each rescue' do
          call_count = 0
          allow(saver).to receive(:save_valid_records) do
            call_count += 1
            raise ActiveRecord::QueryCanceled if call_count <= 2
          end

          saver.execute

          expect(saver.instance_variable_get(:@exceptions_rescued)).to eq(2)
        end
      end

      it 'retries with smaller batch size' do
        expect(saver).to receive(:save_valid_records).and_raise(ActiveRecord::QueryCanceled)
        allow(saver).to receive(:save_valid_records).and_call_original

        expect(saver).to receive(:save_batch_with_retry)
          .with('notes', notes)
          .and_call_original
        smaller_batch_size = (notes.size / described_class::BATCH_SIZE_REDUCTION_FACTOR.to_f).ceil

        (0...described_class::BATCH_SIZE_REDUCTION_FACTOR).each do |i|
          start_index = i * smaller_batch_size
          end_index = [start_index + smaller_batch_size, notes.size].min - 1
          batch = notes[start_index..end_index]

          next if batch.empty?

          expect(saver).to receive(:save_batch_with_retry)
            .with('notes', batch, 1)
            .and_call_original
        end

        saver.execute
      end

      it 'tracks error with Gitlab::ErrorTracking' do
        expect(saver).to receive(:save_valid_records).and_raise(ActiveRecord::QueryCanceled)
        allow(saver).to receive(:save_valid_records).and_call_original

        expect(Gitlab::ErrorTracking).to receive(:track_exception).at_least(:once).with(
          instance_of(ActiveRecord::QueryCanceled),
          hash_including(
            relation_name: 'notes',
            relation_key: 'issues',
            batch_size: kind_of(Integer),
            retry_count: kind_of(Integer)
          )
        )

        saver.execute
      end

      it 'tracks failed subrelations when max retries exceeded' do
        call_count = 0

        allow(saver).to receive(:save_valid_records) do |*args|
          call_count += 1
          raise ActiveRecord::QueryCanceled if call_count <= 4

          saver.method(:save_valid_records).super_method.call(*args)
        end

        saver.execute
        expect(saver.failed_subrelations.present?).to eq(true)
        expect(saver.failed_subrelations.pluck(:record)).to match_array(notes.first)
        expect(saver.failed_subrelations.pluck(:exception)).to all(be_a(ActiveRecord::QueryCanceled))
      end
    end
  end
end
