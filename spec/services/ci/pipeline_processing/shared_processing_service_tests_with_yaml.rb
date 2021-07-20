# frozen_string_literal: true

RSpec.shared_context 'Pipeline Processing Service Tests With Yaml' do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { project.owner }

  where(:test_file_path) do
    Dir.glob(Rails.root.join('spec/services/ci/pipeline_processing/test_cases/*.yml'))
  end

  with_them do
    let(:test_file) { YAML.load_file(test_file_path) }
    let(:pipeline) { Ci::CreatePipelineService.new(project, user, ref: 'master').execute(:pipeline).payload }

    before do
      stub_ci_pipeline_yaml_file(YAML.dump(test_file['config']))
    end

    it 'follows transitions' do
      expect(pipeline).to be_persisted
      Sidekiq::Worker.drain_all # ensure that all async jobs are executed
      check_expectation(test_file.dig('init', 'expect'), "init")

      test_file['transitions'].each_with_index do |transition, idx|
        event_on_jobs(transition['event'], transition['jobs'])
        Sidekiq::Worker.drain_all # ensure that all async jobs are executed
        check_expectation(transition['expect'], "transition:#{idx}")
      end
    end

    private

    def check_expectation(expectation, message)
      expect(current_state.deep_stringify_keys).to eq(expectation), message
    end

    def current_state
      # reload pipeline and all relations
      pipeline.reload

      {
        pipeline: pipeline.status,
        stages: pipeline.stages.pluck(:name, :status).to_h,
        jobs: pipeline.latest_statuses.pluck(:name, :status).to_h
      }
    end

    def event_on_jobs(event, job_names)
      statuses = pipeline.latest_statuses.by_name(job_names).to_a
      expect(statuses.count).to eq(job_names.count) # ensure that we have the same counts

      statuses.each do |status|
        if event == 'play'
          status.play(user)
        else
          status.public_send("#{event}!")
        end
      end
    end
  end
end
