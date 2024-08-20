# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Tags::BulkInsert do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be_with_refind(:job) { create(:ci_build, :unique_name, pipeline: pipeline) }
  let_it_be_with_refind(:other_job) { create(:ci_build, :unique_name, pipeline: pipeline) }

  let(:statuses) { [job, other_job] }
  let(:config) { described_class::NoConfig.new }

  subject(:service) { described_class.new(statuses, config: config) }

  describe '.bulk_insert_tags!' do
    let(:inserter) { instance_double(described_class) }

    it 'delegates to bulk insert class' do
      expect(described_class)
        .to receive(:new)
        .with(statuses, config: nil)
        .and_return(inserter)

      expect(inserter).to receive(:insert!)

      described_class.bulk_insert_tags!(statuses)
    end
  end

  describe '#insert!' do
    context 'without tags' do
      it { expect(service.insert!).to be_truthy }
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

      context 'with no config provided' do
        it 'does not persist tag links' do
          service.insert!

          expect(job.tag_links).to be_empty
          expect(other_job.tag_links).to be_empty
        end
      end

      context 'with config provided by the factory' do
        let(:config) { nil }

        it 'generates a valid config' do
          expect(service.config).to be_a(described_class::BuildsTagsConfiguration)
        end

        context 'with flags' do
          before do
            allow(service.config).to receive(:monomorphic_taggings?) { monomorphic_taggings }
            allow(service.config).to receive(:polymorphic_taggings?) { polymorphic_taggings }
          end

          context 'when writing to both tables' do
            let(:monomorphic_taggings) { true }
            let(:polymorphic_taggings) { true }

            it 'persists tag links and taggings' do
              service.insert!

              expect(job.tag_links).not_to be_empty
              expect(other_job.tag_links).not_to be_empty

              expect(jobs_tagged_with('tag1')).to contain_exactly(job)
              expect(jobs_tagged_with('tag2')).to contain_exactly(job, other_job)
              expect(jobs_tagged_with('tag3')).to contain_exactly(other_job)

              expect(job.taggings).not_to be_empty
              expect(other_job.taggings).not_to be_empty

              expect(Ci::Build.tagged_with('tag1')).to contain_exactly(job)
              expect(Ci::Build.tagged_with('tag2')).to contain_exactly(job, other_job)
              expect(Ci::Build.tagged_with('tag3')).to contain_exactly(other_job)
            end
          end

          context 'when writing only to taggings' do
            let(:monomorphic_taggings) { false }
            let(:polymorphic_taggings) { true }

            it 'persists taggings' do
              service.insert!

              expect(job.tag_links).to be_empty
              expect(other_job.tag_links).to be_empty

              expect(job.taggings).not_to be_empty
              expect(other_job.taggings).not_to be_empty

              expect(Ci::Build.tagged_with('tag1')).to contain_exactly(job)
              expect(Ci::Build.tagged_with('tag2')).to contain_exactly(job, other_job)
              expect(Ci::Build.tagged_with('tag3')).to contain_exactly(other_job)
            end
          end

          context 'when writing only to link table' do
            let(:monomorphic_taggings) { true }
            let(:polymorphic_taggings) { false }

            it 'persists tag links' do
              service.insert!

              expect(job.tag_links).not_to be_empty
              expect(other_job.tag_links).not_to be_empty

              expect(jobs_tagged_with('tag1')).to contain_exactly(job)
              expect(jobs_tagged_with('tag2')).to contain_exactly(job, other_job)
              expect(jobs_tagged_with('tag3')).to contain_exactly(other_job)

              expect(job.taggings).to be_empty
              expect(other_job.taggings).to be_empty
            end
          end

          def jobs_tagged_with(tag)
            scope = Ci::BuildTag
              .where(tag_id: Ci::Tag.where(name: tag))
              .where(Ci::BuildTag.arel_table[:build_id].eq(Ci::Build.arel_table[:id]))
              .where(Ci::BuildTag.arel_table[:partition_id].eq(Ci::Build.arel_table[:partition_id]))

            Ci::Build.where_exists(scope)
          end
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
