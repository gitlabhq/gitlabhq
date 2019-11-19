# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Status::Composite do
  set(:pipeline) { create(:ci_pipeline) }

  before(:all) do
    @statuses = HasStatus::STATUSES_ENUM.map do |status, idx|
      [status, create(:ci_build, pipeline: pipeline, status: status, importing: true)]
    end.to_h

    @statuses_with_allow_failure = HasStatus::STATUSES_ENUM.map do |status, idx|
      [status, create(:ci_build, pipeline: pipeline, status: status, allow_failure: true, importing: true)]
    end.to_h
  end

  describe '#status' do
    shared_examples 'compares composite with SQL status' do
      it 'returns exactly the same result' do
        builds = Ci::Build.where(id: all_statuses)

        expect(composite_status.status).to eq(builds.legacy_status)
        expect(composite_status.warnings?).to eq(builds.failed_but_allowed.any?)
      end
    end

    shared_examples 'validate all combinations' do |perms|
      HasStatus::STATUSES_ENUM.keys.combination(perms).each do |statuses|
        context "with #{statuses.join(",")}" do
          it_behaves_like 'compares composite with SQL status' do
            let(:all_statuses) do
              statuses.map { |status| @statuses[status] }
            end

            let(:composite_status) do
              described_class.new(all_statuses)
            end
          end

          HasStatus::STATUSES_ENUM.each do |allow_failure_status, _|
            context "and allow_failure #{allow_failure_status}" do
              it_behaves_like 'compares composite with SQL status' do
                let(:all_statuses) do
                  statuses.map { |status| @statuses[status] } +
                    [@statuses_with_allow_failure[allow_failure_status]]
                end

                let(:composite_status) do
                  described_class.new(all_statuses)
                end
              end
            end
          end
        end
      end
    end

    it_behaves_like 'validate all combinations', 0
    it_behaves_like 'validate all combinations', 1
    it_behaves_like 'validate all combinations', 2
  end
end
