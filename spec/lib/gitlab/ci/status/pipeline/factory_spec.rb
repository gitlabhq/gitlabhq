require 'spec_helper'

describe Gitlab::Ci::Status::Pipeline::Factory do
  let(:user) { create(:user) }
  let(:project) { pipeline.project }

  subject do
    described_class.new(pipeline, user)
  end

  let(:status) do
    subject.fabricate!
  end

  before do
    project.team << [user, :developer]
  end

  context 'when pipeline has a core status' do
    HasStatus::AVAILABLE_STATUSES.each do |core_status|
      context "when core status is #{core_status}" do
        let(:pipeline) do
          create(:ci_pipeline, status: core_status)
        end

        it "fabricates a core status #{core_status}" do
          expect(status).to be_a(
            Gitlab::Ci::Status.const_get(core_status.capitalize))
        end

        it 'extends core status with common pipeline methods' do
          expect(status).to have_details
          expect(status).not_to have_action
          expect(status.details_path)
            .to include "pipelines/#{pipeline.id}"
        end
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

    it 'fabricates extended "success with warnings" status' do
      expect(status)
        .to be_a Gitlab::Ci::Status::Pipeline::SuccessWithWarnings
    end

    it 'extends core status with common pipeline methods' do
      expect(status).to have_details
    end
  end
end
