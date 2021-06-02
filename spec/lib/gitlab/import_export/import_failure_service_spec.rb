# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::ImportFailureService do
  let(:importable) { create(:project, :builds_enabled, :issues_disabled, name: 'project', path: 'project') }
  let(:label) { create(:label) }
  let(:subject) { described_class.new(importable) }
  let(:action) { "save_relation" }
  let(:relation_key) { "labels" }
  let(:relation_index) { 0 }

  describe '#log_import_failure' do
    let(:standard_error_message) { "StandardError message" }
    let(:exception) { StandardError.new(standard_error_message) }
    let(:correlation_id) { 'my-correlation-id' }
    let(:retry_count) { 2 }
    let(:log_import_failure) do
      subject.log_import_failure(
        source: action,
        relation_key: relation_key,
        relation_index: relation_index,
        exception: exception,
        retry_count: retry_count)
    end

    before do
      # Import is running from the rake task, `correlation_id` is not assigned
      allow(Labkit::Correlation::CorrelationId).to receive(:current_or_new_id).and_return(correlation_id)
    end

    context 'when importable is a group' do
      let(:importable) { create(:group) }

      it_behaves_like 'log import failure', :group_id
    end

    context 'when importable is a project' do
      it_behaves_like 'log import failure', :project_id
    end

    context 'when ImportFailure does not support importable class' do
      let(:importable) { create(:merge_request) }

      it 'raise exception' do
        expect { subject }.to raise_exception(ActiveRecord::AssociationNotFoundError, /Association named 'import_failures' was not found on MergeRequest/)
      end
    end
  end

  describe '#with_retry' do
    let(:perform_retry) do
      subject.with_retry(action: action, relation_key: relation_key, relation_index: relation_index) do
        label.save!
      end
    end

    context 'when exceptions are retriable' do
      where(:exception) { Gitlab::ImportExport::ImportFailureService::RETRIABLE_EXCEPTIONS }

      with_them do
        context 'when retry succeeds' do
          before do
            expect(label).to receive(:save!).and_raise(exception.new)
            expect(label).to receive(:save!).and_return(true)
          end

          it 'retries and logs import failure once with correct params' do
            expect(subject).to receive(:log_import_failure).with(
              source: action,
              relation_key: relation_key,
              relation_index: relation_index,
              exception: instance_of(exception),
              retry_count: 1).once

            perform_retry
          end
        end

        context 'when retry continues to fail with intermittent errors' do
          let(:maximum_retry_count) do
            Retriable.config.tries
          end

          before do
            expect(label).to receive(:save!)
              .exactly(maximum_retry_count).times
              .and_raise(exception.new)
          end

          it 'retries the number of times allowed and raise exception', :aggregate_failures do
            expect { perform_retry }.to raise_exception(exception)
          end

          it 'logs import failure each time and raise exception', :aggregate_failures do
            maximum_retry_count.times do |index|
              retry_count = index + 1

              expect(subject).to receive(:log_import_failure).with(
                source: action, relation_key: relation_key,
                relation_index: relation_index,
                exception: instance_of(exception),
                retry_count: retry_count)
            end

            expect { perform_retry }.to raise_exception(exception)
          end
        end
      end
    end

    context 'when exception is not retriable' do
      let(:exception) { StandardError.new }

      it 'raise the exception', :aggregate_failures do
        expect(label).to receive(:save!).once.and_raise(exception)
        expect(subject).not_to receive(:log_import_failure)
        expect { perform_retry }.to raise_exception(exception)
      end
    end
  end
end
