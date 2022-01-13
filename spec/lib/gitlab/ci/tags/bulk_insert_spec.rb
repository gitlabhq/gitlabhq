# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Tags::BulkInsert do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be_with_refind(:job) { create(:ci_build, :unique_name, pipeline: pipeline) }
  let_it_be_with_refind(:other_job) { create(:ci_build, :unique_name, pipeline: pipeline) }

  let(:statuses) { [job, other_job] }

  subject(:service) { described_class.new(statuses) }

  describe 'gem version' do
    let(:acceptable_version) { '9.0.0' }

    let(:error_message) do
      <<~MESSAGE
      A mechanism depending on internals of 'act-as-taggable-on` has been designed
      to bulk insert tags for Ci::Build records.
      Please review the code carefully before updating the gem version
      https://gitlab.com/gitlab-org/gitlab/-/issues/350053
      MESSAGE
    end

    it { expect(ActsAsTaggableOn::VERSION).to eq(acceptable_version), error_message }
  end

  describe '#insert!' do
    context 'without tags' do
      it { expect(service.insert!).to be_falsey }
    end

    context 'with tags' do
      before do
        job.tag_list = %w[tag1 tag2]
        other_job.tag_list = %w[tag2 tag3 tag4]
      end

      it 'persists tags' do
        expect(service.insert!).to be_truthy

        expect(job.reload.tag_list).to match_array(%w[tag1 tag2])
        expect(other_job.reload.tag_list).to match_array(%w[tag2 tag3 tag4])
      end
    end

    context 'with tags for only one job' do
      before do
        job.tag_list = %w[tag1 tag2]
      end

      it 'persists tags' do
        expect(service.insert!).to be_truthy

        expect(job.reload.tag_list).to match_array(%w[tag1 tag2])
        expect(other_job.reload.tag_list).to be_empty
      end
    end
  end
end
