require 'spec_helper'

describe Gitlab::Ci::Status::Pipeline::Factory do
  let(:user) { create(:user) }
  let(:project) { pipeline.project }
  let(:status) { factory.fabricate! }
  let(:factory) { described_class.new(pipeline, user) }

  before do
    project.add_developer(user)
  end

  context 'when pipeline has a core status' do
    (HasStatus::AVAILABLE_STATUSES - [HasStatus::BLOCKED_STATUS])
      .each do |simple_status|
      context "when core status is #{simple_status}" do
        let(:pipeline) { create(:ci_pipeline, status: simple_status) }

        let(:expected_status) do
          Gitlab::Ci::Status.const_get(simple_status.capitalize)
        end

        it "matches correct core status for #{simple_status}" do
          expect(factory.core_status).to be_a expected_status
        end

        it 'does not match extended statuses' do
          expect(factory.extended_statuses).to be_empty
        end

        it "fabricates a core status #{simple_status}" do
          expect(status).to be_a expected_status
        end

        it 'extends core status with common pipeline methods' do
          expect(status).to have_details
          expect(status).not_to have_action
          expect(status.details_path)
            .to include "pipelines/#{pipeline.id}"
        end
      end
    end

    context "when core status is manual" do
      let(:pipeline) { create(:ci_pipeline, status: :manual) }

      it "matches manual core status" do
        expect(factory.core_status)
          .to be_a Gitlab::Ci::Status::Manual
      end

      it 'matches a correct extended statuses' do
        expect(factory.extended_statuses)
          .to eq [Gitlab::Ci::Status::Pipeline::Blocked]
      end

      it 'extends core status with common pipeline methods' do
        expect(status).to have_details
        expect(status).not_to have_action
        expect(status.details_path)
          .to include "pipelines/#{pipeline.id}"
      end
    end
  end

  context 'when pipeline has warnings' do
    let(:pipeline) do
      create(:ci_pipeline, status: :success)
    end

    before do
      create(:ci_build, :allowed_to_fail, :failed, pipeline: pipeline)
    end

    it 'matches correct core status' do
      expect(factory.core_status).to be_a Gitlab::Ci::Status::Success
    end

    it 'matches correct extended statuses' do
      expect(factory.extended_statuses)
        .to eq [Gitlab::Ci::Status::SuccessWarning]
    end

    it 'fabricates extended "success with warnings" status' do
      expect(status).to be_a Gitlab::Ci::Status::SuccessWarning
    end

    it 'extends core status with common pipeline method' do
      expect(status).to have_details
      expect(status.details_path).to include "pipelines/#{pipeline.id}"
    end
  end
end
