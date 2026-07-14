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

    context 'when job definition record is deleted' do
      # This would only happen to old jobs whose config was not migrated to ci_job_definitions. See
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194777#note_2578529419.
      before do
        job.job_definition_instance.delete
        job.reload
      end

      it { is_expected.to be_degenerated }
    end
  end

  describe '#degenerate!' do
    before do
      job.needs.create!(name: 'another-job')
    end

    it 'drops disposable job data' do
      job.degenerate!

      expect(job.reload).to be_degenerated
      expect(job.options).to be_empty
      expect(job.yaml_variables).to be_empty
      expect(job.needs).to be_empty
      expect(job.job_definition_instance).to be_nil
    end
  end
end
