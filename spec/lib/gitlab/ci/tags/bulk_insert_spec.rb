# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Tags::BulkInsert do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be_with_refind(:job) { create(:ci_build, :unique_name, pipeline: pipeline, project: project) }
  let_it_be_with_refind(:other_job) { create(:ci_build, :unique_name, pipeline: pipeline, project: project) }
  let_it_be_with_refind(:bridge) { create(:ci_bridge, pipeline: pipeline, project: project) }

  let(:statuses) { [job, bridge, other_job] }

  subject(:service) { described_class.new(statuses, tags_list) }

  describe '#insert!' do
    context 'without tags' do
      let(:tags_list) { {} }

      it { expect(service.insert!).to be_falsey }
    end

    context 'with tags' do
      let(:tags_list) do
        {
          job.name => %w[tag1 tag2],
          other_job.name => %w[tag2 tag3 tag4]
        }
      end

      it 'persists tags' do
        expect(service.insert!).to be_truthy

        expect(job.reload.tag_list).to match_array(%w[tag1 tag2])
        expect(other_job.reload.tag_list).to match_array(%w[tag2 tag3 tag4])
      end
    end
  end
end
