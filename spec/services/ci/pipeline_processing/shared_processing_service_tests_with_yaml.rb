# frozen_string_literal: true

shared_context 'Pipeline Processing Service Tests With Yaml' do
  where(:test_file_path) do
    Dir.glob(Rails.root.join('spec/services/ci/pipeline_processing/test_cases/*.yml'))
  end

  with_them do
    let(:test_file) { YAML.load_file(test_file_path) }

    let(:user)     { create(:user) }
    let(:project)  { create(:project, :repository) }
    let(:pipeline) { Ci::CreatePipelineService.new(project, user, ref: 'master').execute(:pipeline) }

    before do
      stub_ci_pipeline_yaml_file(YAML.dump(test_file['config']))
      stub_not_protect_default_branch
      project.add_developer(user)
    end

    it 'follows transitions', :sidekiq_inline do
      expect(pipeline).to be_persisted
      check_expectation(test_file.dig('init', 'expect'))

      test_file['transitions'].each do |transition|
        event_on_jobs(transition['event'], transition['jobs'])
        check_expectation(transition['expect'])
      end
    end

    private

    def check_expectation(expectation)
      expectation.each do |key, value|
        case key
        when 'pipeline'
          expect(pipeline.reload.status).to eq(value)
        when 'stages'
          expect(pipeline.stages.pluck(:name, :status).to_h).to eq(value)
        when 'jobs'
          expect(pipeline.builds.latest.pluck(:name, :status).to_h).to eq(value)
        end
      end
    end

    def event_on_jobs(event, job_names)
      builds = pipeline.builds.latest.where(name: job_names).to_a
      expect(builds.count).to eq(job_names.count) # ensure that we have the same counts

      builds.each { |build| build.public_send("#{event}!") }
    end
  end
end
