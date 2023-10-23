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
    let(:acceptable_version) { '10.0.0' }

    let(:error_message) do
      <<~MESSAGE
      A mechanism depending on internals of 'act-as-taggable-on` has been designed
      to bulk insert tags for Ci::Build/Ci::Runner records.
      Please review the code carefully before updating the gem version
      https://gitlab.com/gitlab-org/gitlab/-/issues/350053
      MESSAGE
    end

    it { expect(ActsAsTaggableOn::VERSION).to eq(acceptable_version), error_message }
  end

  describe '.bulk_insert_tags!' do
    let(:inserter) { instance_double(described_class) }

    it 'delegates to bulk insert class' do
      expect(described_class)
        .to receive(:new)
        .with(statuses)
        .and_return(inserter)

      expect(inserter).to receive(:insert!)

      described_class.bulk_insert_tags!(statuses)
    end
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

      it 'persists taggings' do
        service.insert!

        expect(job.taggings.size).to eq(2)
        expect(other_job.taggings.size).to eq(3)

        expect(Ci::Build.tagged_with('tag1')).to include(job)
        expect(Ci::Build.tagged_with('tag2')).to include(job, other_job)
        expect(Ci::Build.tagged_with('tag3')).to include(other_job)
      end

      it 'strips tags' do
        job.tag_list = ['       taga', 'tagb      ', '   tagc    ']

        service.insert!
        expect(job.tags.map(&:name)).to match_array(%w[taga tagb tagc])
      end

      context 'when batching inserts for tags' do
        before do
          stub_const("#{described_class}::TAGS_BATCH_SIZE", 2)
        end

        it 'inserts tags in batches' do
          recorder = ActiveRecord::QueryRecorder.new { service.insert! }
          count = recorder.log.count { |query| query.include?('INSERT INTO "tags"') }

          expect(count).to eq(2)
        end
      end

      context 'when batching inserts for taggings' do
        before do
          stub_const("#{described_class}::TAGGINGS_BATCH_SIZE", 2)
        end

        it 'inserts taggings in batches' do
          recorder = ActiveRecord::QueryRecorder.new { service.insert! }
          count = recorder.log.count { |query| query.include?('INSERT INTO "taggings"') }

          expect(count).to eq(3)
        end
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

      it 'persists taggings' do
        service.insert!

        expect(job.taggings.size).to eq(2)

        expect(Ci::Build.tagged_with('tag1')).to include(job)
        expect(Ci::Build.tagged_with('tag2')).to include(job)
      end
    end
  end
end
