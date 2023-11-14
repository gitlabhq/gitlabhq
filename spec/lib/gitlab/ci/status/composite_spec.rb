# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Composite, feature_category: :continuous_integration do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  before_all do
    @statuses = Ci::HasStatus::STATUSES_ENUM.to_h do |status, idx|
      [status, create(:ci_build, pipeline: pipeline, status: status, importing: true)]
    end

    @statuses_with_allow_failure = Ci::HasStatus::STATUSES_ENUM.to_h do |status, idx|
      [status, create(:ci_build, pipeline: pipeline, status: status, allow_failure: true, importing: true)]
    end
  end

  describe '.initialize' do
    subject(:composite_status) { described_class.new(all_statuses) }

    context 'when passing a single status' do
      let(:all_statuses) { @statuses[:success] }

      it 'raises ArgumentError' do
        expect { composite_status }.to raise_error(ArgumentError, 'all_jobs needs to respond to `.pluck`')
      end
    end
  end

  describe '#status' do
    using RSpec::Parameterized::TableSyntax

    shared_examples 'compares status and warnings' do
      let(:composite_status) do
        described_class.new(all_statuses, dag: dag)
      end

      it 'returns status and warnings?' do
        expect(composite_status.status).to eq(result)
        expect(composite_status.warnings?).to eq(has_warnings)
      end
    end

    context 'allow_failure: false' do
      where(:build_statuses, :dag, :result, :has_warnings) do
        %i[skipped]                         | false | 'skipped'              | false
        %i[skipped success]                 | false | 'success'              | false
        %i[skipped success]                 | true  | 'skipped'              | false
        %i[created]                         | false | 'created'              | false
        %i[preparing]                       | false | 'preparing'            | false
        %i[canceled success skipped]        | false | 'canceled'             | false
        %i[canceled success skipped]        | true  | 'skipped'              | false
        %i[pending created skipped]         | false | 'pending'              | false
        %i[pending created skipped success] | false | 'running'              | false
        %i[running created skipped success] | false | 'running'              | false
        %i[pending created skipped]         | true  | 'skipped'              | false
        %i[pending created skipped success] | true  | 'skipped'              | false
        %i[running created skipped success] | true  | 'skipped'              | false
        %i[success waiting_for_resource]    | false | 'waiting_for_resource' | false
        %i[success waiting_for_callback]    | false | 'waiting_for_callback' | false
        %i[success manual]                  | false | 'manual'               | false
        %i[success scheduled]               | false | 'scheduled'            | false
        %i[created preparing]               | false | 'preparing'            | false
        %i[created success pending]         | false | 'running'              | false
        %i[skipped success failed]          | false | 'failed'               | false
        %i[skipped success failed]          | true  | 'skipped'              | false
        %i[success manual]                  | true  | 'manual'               | false
        %i[success failed created]          | true  | 'running'              | false
      end

      with_them do
        let(:all_statuses) do
          build_statuses.map { |status| @statuses[status] }
        end

        it_behaves_like 'compares status and warnings'
      end
    end

    context 'allow_failure: true' do
      where(:build_statuses, :dag, :result, :has_warnings) do
        %i[manual]           | false | 'skipped'   | false
        %i[skipped failed]   | false | 'success'   | true
        %i[skipped failed]   | true  | 'skipped'   | true
        %i[success manual]   | true  | 'skipped'   | false
        %i[success manual]   | false | 'success'   | false
        %i[created failed]   | false | 'created'   | true
        %i[preparing manual] | false | 'preparing' | false
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
