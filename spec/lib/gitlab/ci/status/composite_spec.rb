# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Composite do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  before_all do
    @statuses = Ci::HasStatus::STATUSES_ENUM.map do |status, idx|
      [status, create(:ci_build, pipeline: pipeline, status: status, importing: true)]
    end.to_h

    @statuses_with_allow_failure = Ci::HasStatus::STATUSES_ENUM.map do |status, idx|
      [status, create(:ci_build, pipeline: pipeline, status: status, allow_failure: true, importing: true)]
    end.to_h
  end

  describe '#status' do
    using RSpec::Parameterized::TableSyntax

    shared_examples 'compares status and warnings' do
      let(:composite_status) do
        described_class.new(all_statuses)
      end

      it 'returns status and warnings?' do
        expect(composite_status.status).to eq(result)
        expect(composite_status.warnings?).to eq(has_warnings)
      end
    end

    context 'allow_failure: false' do
      where(:build_statuses, :result, :has_warnings) do
        %i(skipped) | 'skipped' | false
        %i(skipped success) | 'success' | false
        %i(created) | 'created' | false
        %i(preparing) | 'preparing' | false
        %i(canceled success skipped) | 'canceled' | false
        %i(pending created skipped) | 'pending' | false
        %i(pending created skipped success) | 'running' | false
        %i(running created skipped success) | 'running' | false
        %i(success waiting_for_resource) | 'waiting_for_resource' | false
        %i(success manual) | 'manual' | false
        %i(success scheduled) | 'scheduled' | false
        %i(created preparing) | 'preparing' | false
        %i(created success pending) | 'running' | false
        %i(skipped success failed) | 'failed' | false
      end

      with_them do
        let(:all_statuses) do
          build_statuses.map { |status| @statuses[status] }
        end

        it_behaves_like 'compares status and warnings'
      end
    end

    context 'allow_failure: true' do
      where(:build_statuses, :result, :has_warnings) do
        %i(manual) | 'skipped' | false
        %i(skipped failed) | 'success' | true
        %i(created failed) | 'created' | true
        %i(preparing manual) | 'preparing' | false
      end

      with_them do
        let(:all_statuses) do
          build_statuses.map { |status| @statuses_with_allow_failure[status] }
        end

        it_behaves_like 'compares status and warnings'
      end
    end
  end
end
