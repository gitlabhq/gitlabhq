# frozen_string_literal: true

# Requires a context containing a valid job as subject.
RSpec.shared_examples 'a degenerable job' do
  describe '#degenerated?' do
    it { is_expected.not_to be_degenerated }

    context 'when job is degenerated' do
      before do
        job.degenerate!
        job.reload
      end

      it { is_expected.to be_degenerated }
    end

    context 'when job metadata record is deleted' do
      # This would only happen to old jobs that never had execution_config
      # and whose metadata were not migrated to ci_job_prototypes. See
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194777#note_2578529419.
      before do
        job.try(:execution_config)&.delete
        job.metadata.delete
        job.job_definition_instance.delete
        job.reload
      end

      it { is_expected.to be_degenerated }

      context 'when p_ci_builds.options is present' do
        before do
          # Very old jobs populated this column instead of metadata
          job.update_column(:options, { my_config: 'value' })
        end

        it { is_expected.not_to be_degenerated }
      end
    end
  end

  describe '#degenerate!' do
    before do
      create(:ci_build_metadata, build: job)
      job.needs.create!(name: 'another-job')
    end

    it 'drops metadata' do
      job.degenerate!

      expect(job.reload).to be_degenerated
      expect(job.options).to be_empty
      expect(job.yaml_variables).to be_empty
      expect(job.needs).to be_empty
      expect(job.metadata).to be_nil
      expect(job.try(:execution_config)).to be_nil
    end
  end
end
