require 'spec_helper'

describe Ci::Build, models: true do
  let(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: project.default_branch,
                         status: 'success')
  end

  let(:build) { create(:ci_build, pipeline: pipeline) }

  it { is_expected.to validate_presence_of :ref }

  it { is_expected.to respond_to :trace_html }

  describe '#first_pending' do
    let!(:first) { create(:ci_build, pipeline: pipeline, status: 'pending', created_at: Date.yesterday) }
    let!(:second) { create(:ci_build, pipeline: pipeline, status: 'pending') }
    subject { Ci::Build.first_pending }

    it { is_expected.to be_a(Ci::Build) }
    it('returns with the first pending build') { is_expected.to eq(first) }
  end

  describe '#create_from' do
    before do
      build.status = 'success'
      build.save
    end
    let(:create_from_build) { Ci::Build.create_from build }

    it 'exists a pending task' do
      expect(Ci::Build.pending.count(:all)).to eq 0
      create_from_build
      expect(Ci::Build.pending.count(:all)).to be > 0
    end
  end

  describe '#ignored?' do
    subject { build.ignored? }

    context 'if build is not allowed to fail' do
      before do
        build.allow_failure = false
      end

      context 'and build.status is success' do
        before do
          build.status = 'success'
        end

        it { is_expected.to be_falsey }
      end

      context 'and build.status is failed' do
        before do
          build.status = 'failed'
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'if build is allowed to fail' do
      before do
        build.allow_failure = true
      end

      context 'and build.status is success' do
        before do
          build.status = 'success'
        end

        it { is_expected.to be_falsey }
      end

      context 'and build.status is failed' do
        before do
          build.status = 'failed'
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#trace' do
    subject { build.trace_html }

    it { is_expected.to be_empty }

    context 'if build.trace contains text' do
      let(:text) { 'example output' }
      before do
        build.trace = text
      end

      it { is_expected.to include(text) }
      it { expect(subject.length).to be >= text.length }
    end

    context 'if build.trace hides token' do
      let(:token) { 'my_secret_token' }

      before do
        build.project.update_attributes(runners_token: token)
        build.update_attributes(trace: token)
      end

      it { is_expected.not_to include(token) }
    end
  end

  # TODO: build timeout
  # describe :timeout do
  #   subject { build.timeout }
  #
  #   it { is_expected.to eq(pipeline.project.timeout) }
  # end

  describe '#options' do
    let(:options) do
      {
        image: "ruby:2.1",
        services: [
          "postgres"
        ]
      }
    end

    subject { build.options }
    it { is_expected.to eq(options) }
  end

  # TODO: allow_git_fetch
  # describe :allow_git_fetch do
  #   subject { build.allow_git_fetch }
  #
  #   it { is_expected.to eq(project.allow_git_fetch) }
  # end

  describe '#project' do
    subject { build.project }

    it { is_expected.to eq(pipeline.project) }
  end

  describe '#project_id' do
    subject { build.project_id }

    it { is_expected.to eq(pipeline.project_id) }
  end

  describe '#project_name' do
    subject { build.project_name }

    it { is_expected.to eq(project.name) }
  end

  describe '#extract_coverage' do
    context 'valid content & regex' do
      subject { build.extract_coverage('Coverage 1033 / 1051 LOC (98.29%) covered', '\(\d+.\d+\%\) covered') }

      it { is_expected.to eq(98.29) }
    end

    context 'valid content & bad regex' do
      subject { build.extract_coverage('Coverage 1033 / 1051 LOC (98.29%) covered', 'very covered') }

      it { is_expected.to be_nil }
    end

    context 'no coverage content & regex' do
      subject { build.extract_coverage('No coverage for today :sad:', '\(\d+.\d+\%\) covered') }

      it { is_expected.to be_nil }
    end

    context 'multiple results in content & regex' do
      subject { build.extract_coverage(' (98.39%) covered. (98.29%) covered', '\(\d+.\d+\%\) covered') }

      it { is_expected.to eq(98.29) }
    end

    context 'using a regex capture' do
      subject { build.extract_coverage('TOTAL      9926   3489    65%', 'TOTAL\s+\d+\s+\d+\s+(\d{1,3}\%)') }

      it { is_expected.to eq(65) }
    end
  end

  describe '#variables' do
    let(:container_registry_enabled) { false }
    let(:predefined_variables) do
      [
        { key: 'CI', value: 'true', public: true },
        { key: 'GITLAB_CI', value: 'true', public: true },
        { key: 'CI_BUILD_ID', value: build.id.to_s, public: true },
        { key: 'CI_BUILD_TOKEN', value: build.token, public: false },
        { key: 'CI_BUILD_REF', value: build.sha, public: true },
        { key: 'CI_BUILD_BEFORE_SHA', value: build.before_sha, public: true },
        { key: 'CI_BUILD_REF_NAME', value: 'master', public: true },
        { key: 'CI_BUILD_NAME', value: 'test', public: true },
        { key: 'CI_BUILD_STAGE', value: 'test', public: true },
        { key: 'CI_SERVER_NAME', value: 'GitLab', public: true },
        { key: 'CI_SERVER_VERSION', value: Gitlab::VERSION, public: true },
        { key: 'CI_SERVER_REVISION', value: Gitlab::REVISION, public: true },
        { key: 'CI_PROJECT_ID', value: project.id.to_s, public: true },
        { key: 'CI_PROJECT_NAME', value: project.path, public: true },
        { key: 'CI_PROJECT_PATH', value: project.path_with_namespace, public: true },
        { key: 'CI_PROJECT_NAMESPACE', value: project.namespace.path, public: true },
        { key: 'CI_PROJECT_URL', value: project.web_url, public: true },
        { key: 'CI_PIPELINE_ID', value: pipeline.id.to_s, public: true }
      ]
    end

    before do
      stub_container_registry_config(enabled: container_registry_enabled, host_port: 'registry.example.com')
    end

    subject { build.variables }

    context 'returns variables' do
      before do
        build.yaml_variables = []
      end

      it { is_expected.to eq(predefined_variables) }
    end

    context 'when build is for tag' do
      let(:tag_variable) do
        { key: 'CI_BUILD_TAG', value: 'master', public: true }
      end

      before do
        build.update_attributes(tag: true)
      end

      it { is_expected.to include(tag_variable) }
    end

    context 'when secure variable is defined' do
      let(:secure_variable) do
        { key: 'SECRET_KEY', value: 'secret_value', public: false }
      end

      before do
        build.project.variables << Ci::Variable.new(key: 'SECRET_KEY', value: 'secret_value')
      end

      it { is_expected.to include(secure_variable) }
    end

    context 'when build is for triggers' do
      let(:trigger) { create(:ci_trigger, project: project) }
      let(:trigger_request) { create(:ci_trigger_request_with_variables, pipeline: pipeline, trigger: trigger) }
      let(:user_trigger_variable) do
        { key: :TRIGGER_KEY_1, value: 'TRIGGER_VALUE_1', public: false }
      end
      let(:predefined_trigger_variable) do
        { key: 'CI_BUILD_TRIGGERED', value: 'true', public: true }
      end

      before do
        build.trigger_request = trigger_request
      end

      it { is_expected.to include(user_trigger_variable) }
      it { is_expected.to include(predefined_trigger_variable) }
    end

    context 'when yaml_variables are undefined' do
      before do
        build.yaml_variables = nil
      end

      context 'use from gitlab-ci.yml' do
        before do
          stub_ci_pipeline_yaml_file(config)
        end

        context 'if config is not found' do
          let(:config) { nil }

          it { is_expected.to eq(predefined_variables) }
        end

        context 'if config does not have a questioned job' do
          let(:config) do
            YAML.dump({
              test_other: {
                script: 'Hello World'
              }
            })
          end

          it { is_expected.to eq(predefined_variables) }
        end

        context 'if config has variables' do
          let(:config) do
            YAML.dump({
              test: {
                script: 'Hello World',
                variables: {
                  KEY: 'value'
                }
              }
            })
          end
          let(:variables) do
            [{ key: :KEY, value: 'value', public: true }]
          end

          it { is_expected.to eq(predefined_variables + variables) }
        end
      end
    end

    context 'when container registry is enabled' do
      let(:container_registry_enabled) { true }
      let(:ci_registry) do
        { key: 'CI_REGISTRY',  value: 'registry.example.com',  public: true }
      end
      let(:ci_registry_image) do
        { key: 'CI_REGISTRY_IMAGE',  value: project.container_registry_repository_url, public: true }
      end

      context 'and is disabled for project' do
        before do
          project.update(container_registry_enabled: false)
        end

        it { is_expected.to include(ci_registry) }
        it { is_expected.not_to include(ci_registry_image) }
      end

      context 'and is enabled for project' do
        before do
          project.update(container_registry_enabled: true)
        end

        it { is_expected.to include(ci_registry) }
        it { is_expected.to include(ci_registry_image) }
      end
    end

    context 'when runner is assigned to build' do
      let(:runner) { create(:ci_runner, description: 'description', tag_list: ['docker', 'linux']) }

      before do
        build.update(runner: runner)
      end

      it { is_expected.to include({ key: 'CI_RUNNER_ID', value: runner.id.to_s, public: true }) }
      it { is_expected.to include({ key: 'CI_RUNNER_DESCRIPTION', value: 'description', public: true }) }
      it { is_expected.to include({ key: 'CI_RUNNER_TAGS', value: 'docker, linux', public: true }) }
    end

    context 'returns variables in valid order' do
      before do
        allow(build).to receive(:predefined_variables) { ['predefined'] }
        allow(project).to receive(:predefined_variables) { ['project'] }
        allow(pipeline).to receive(:predefined_variables) { ['pipeline'] }
        allow(build).to receive(:yaml_variables) { ['yaml'] }
        allow(project).to receive(:secret_variables) { ['secret'] }
      end

      it { is_expected.to eq(%w[predefined project pipeline yaml secret]) }
    end
  end

  describe '#has_tags?' do
    context 'when build has tags' do
      subject { create(:ci_build, tag_list: ['tag']) }
      it { is_expected.to have_tags }
    end

    context 'when build does not have tags' do
      subject { create(:ci_build, tag_list: []) }
      it { is_expected.not_to have_tags }
    end
  end

  describe '#any_runners_online?' do
    subject { build.any_runners_online? }

    context 'when no runners' do
      it { is_expected.to be_falsey }
    end

    context 'if there are runner' do
      let(:runner) { create(:ci_runner) }

      before do
        build.project.runners << runner
        runner.update_attributes(contacted_at: 1.second.ago)
      end

      it { is_expected.to be_truthy }

      it 'that is inactive' do
        runner.update_attributes(active: false)
        is_expected.to be_falsey
      end

      it 'that is not online' do
        runner.update_attributes(contacted_at: nil)
        is_expected.to be_falsey
      end

      it 'that cannot handle build' do
        expect_any_instance_of(Ci::Runner).to receive(:can_pick?).and_return(false)
        is_expected.to be_falsey
      end
    end
  end

  describe '#stuck?' do
    subject { build.stuck? }

    %w(pending).each do |state|
      context "if commit_status.status is #{state}" do
        before do
          build.status = state
        end

        it { is_expected.to be_truthy }

        context "and there are specific runner" do
          let(:runner) { create(:ci_runner, contacted_at: 1.second.ago) }

          before do
            build.project.runners << runner
            runner.save
          end

          it { is_expected.to be_falsey }
        end
      end
    end

    %w(success failed canceled running).each do |state|
      context "if commit_status.status is #{state}" do
        before do
          build.status = state
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#artifacts?' do
    subject { build.artifacts? }

    context 'artifacts archive does not exist' do
      before do
        build.update_attributes(artifacts_file: nil)
      end

      it { is_expected.to be_falsy }
    end

    context 'artifacts archive exists' do
      let(:build) { create(:ci_build, :artifacts) }
      it { is_expected.to be_truthy }

      context 'is expired' do
        before { build.update(artifacts_expire_at: Time.now - 7.days)  }
        it { is_expected.to be_falsy }
      end

      context 'is not expired' do
        before { build.update(artifacts_expire_at: Time.now + 7.days)  }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#artifacts_expired?' do
    subject { build.artifacts_expired? }

    context 'is expired' do
      before { build.update(artifacts_expire_at: Time.now - 7.days)  }

      it { is_expected.to be_truthy }
    end

    context 'is not expired' do
      before { build.update(artifacts_expire_at: Time.now + 7.days)  }

      it { is_expected.to be_falsey }
    end
  end

  describe '#artifacts_metadata?' do
    subject { build.artifacts_metadata? }
    context 'artifacts metadata does not exist' do
      it { is_expected.to be_falsy }
    end

    context 'artifacts archive is a zip file and metadata exists' do
      let(:build) { create(:ci_build, :artifacts) }
      it { is_expected.to be_truthy }
    end
  end
  describe '#repo_url' do
    let(:build) { create(:ci_build) }
    let(:project) { build.project }

    subject { build.repo_url }

    it { is_expected.to be_a(String) }
    it { is_expected.to end_with(".git") }
    it { is_expected.to start_with(project.web_url[0..6]) }
    it { is_expected.to include(build.token) }
    it { is_expected.to include('gitlab-ci-token') }
    it { is_expected.to include(project.web_url[7..-1]) }
  end

  describe '#artifacts_expire_in' do
    subject { build.artifacts_expire_in }
    it { is_expected.to be_nil }

    context 'when artifacts_expire_at is specified' do
      let(:expire_at) { Time.now + 7.days }

      before { build.artifacts_expire_at = expire_at }

      it { is_expected.to be_within(5).of(expire_at - Time.now) }
    end
  end

  describe '#artifacts_expire_in=' do
    subject { build.artifacts_expire_in }

    it 'when assigning valid duration' do
      build.artifacts_expire_in = '7 days'

      is_expected.to be_within(10).of(7.days.to_i)
    end

    it 'when assigning invalid duration' do
      expect { build.artifacts_expire_in = '7 elephants' }.to raise_error(ChronicDuration::DurationParseError)
      is_expected.to be_nil
    end

    it 'when resseting value' do
      build.artifacts_expire_in = nil

      is_expected.to be_nil
    end
  end

  describe '#keep_artifacts!' do
    let(:build) { create(:ci_build, artifacts_expire_at: Time.now + 7.days) }

    it 'to reset expire_at' do
      build.keep_artifacts!

      expect(build.artifacts_expire_at).to be_nil
    end
  end

  describe '#depends_on_builds' do
    let!(:build) { create(:ci_build, pipeline: pipeline, name: 'build', stage_idx: 0, stage: 'build') }
    let!(:rspec_test) { create(:ci_build, pipeline: pipeline, name: 'rspec', stage_idx: 1, stage: 'test') }
    let!(:rubocop_test) { create(:ci_build, pipeline: pipeline, name: 'rubocop', stage_idx: 1, stage: 'test') }
    let!(:staging) { create(:ci_build, pipeline: pipeline, name: 'staging', stage_idx: 2, stage: 'deploy') }

    it 'expects to have no dependents if this is first build' do
      expect(build.depends_on_builds).to be_empty
    end

    it 'expects to have one dependent if this is test' do
      expect(rspec_test.depends_on_builds.map(&:id)).to contain_exactly(build.id)
    end

    it 'expects to have all builds from build and test stage if this is last' do
      expect(staging.depends_on_builds.map(&:id)).to contain_exactly(build.id, rspec_test.id, rubocop_test.id)
    end

    it 'expects to have retried builds instead the original ones' do
      retried_rspec = Ci::Build.retry(rspec_test)
      expect(staging.depends_on_builds.map(&:id)).to contain_exactly(build.id, retried_rspec.id, rubocop_test.id)
    end
  end

  def create_mr(build, pipeline, factory: :merge_request, created_at: Time.now)
    create(factory, source_project_id: pipeline.gl_project_id,
                    target_project_id: pipeline.gl_project_id,
                    source_branch: build.ref,
                    created_at: created_at)
  end

  describe '#merge_request' do
    context 'when a MR has a reference to the pipeline' do
      before do
        @merge_request = create_mr(build, pipeline, factory: :merge_request)

        commits = [double(id: pipeline.sha)]
        allow(@merge_request).to receive(:commits).and_return(commits)
        allow(MergeRequest).to receive_message_chain(:includes, :where, :reorder).and_return([@merge_request])
      end

      it 'returns the single associated MR' do
        expect(build.merge_request.id).to eq(@merge_request.id)
      end
    end

    context 'when there is not a MR referencing the pipeline' do
      it 'returns nil' do
        expect(build.merge_request).to be_nil
      end
    end

    context 'when more than one MR have a reference to the pipeline' do
      before do
        @merge_request = create_mr(build, pipeline, factory: :merge_request)
        @merge_request.close!
        @merge_request2 = create_mr(build, pipeline, factory: :merge_request)

        commits = [double(id: pipeline.sha)]
        allow(@merge_request).to receive(:commits).and_return(commits)
        allow(@merge_request2).to receive(:commits).and_return(commits)
        allow(MergeRequest).to receive_message_chain(:includes, :where, :reorder).and_return([@merge_request, @merge_request2])
      end

      it 'returns the first MR' do
        expect(build.merge_request.id).to eq(@merge_request.id)
      end
    end

    context 'when a Build is created after the MR' do
      before do
        @merge_request = create_mr(build, pipeline, factory: :merge_request_with_diffs)
        pipeline2 = create(:ci_pipeline, project: project)
        @build2 = create(:ci_build, pipeline: pipeline2)

        commits = [double(id: pipeline.sha), double(id: pipeline2.sha)]
        allow(@merge_request).to receive(:commits).and_return(commits)
        allow(MergeRequest).to receive_message_chain(:includes, :where, :reorder).and_return([@merge_request])
      end

      it 'returns the current MR' do
        expect(@build2.merge_request.id).to eq(@merge_request.id)
      end
    end
  end

  describe 'build erasable' do
    shared_examples 'erasable' do
      it 'removes artifact file' do
        expect(build.artifacts_file.exists?).to be_falsy
      end

      it 'removes artifact metadata file' do
        expect(build.artifacts_metadata.exists?).to be_falsy
      end

      it 'erases build trace in trace file' do
        expect(build.trace).to be_empty
      end

      it 'sets erased to true' do
        expect(build.erased?).to be true
      end

      it 'sets erase date' do
        expect(build.erased_at).not_to be_falsy
      end
    end

    context 'build is not erasable' do
      let!(:build) { create(:ci_build) }

      describe '#erase' do
        subject { build.erase }

        it { is_expected.to be false }
      end

      describe '#erasable?' do
        subject { build.erasable? }
        it { is_expected.to eq false }
      end
    end

    context 'build is erasable' do
      let!(:build) { create(:ci_build, :trace, :success, :artifacts) }

      describe '#erase' do
        before do
          build.erase(erased_by: user)
        end

        context 'erased by user' do
          let!(:user) { create(:user, username: 'eraser') }

          include_examples 'erasable'

          it 'records user who erased a build' do
            expect(build.erased_by).to eq user
          end
        end

        context 'erased by system' do
          let(:user) { nil }

          include_examples 'erasable'

          it 'does not set user who erased a build' do
            expect(build.erased_by).to be_nil
          end
        end
      end

      describe '#erasable?' do
        subject { build.erasable? }
        it { is_expected.to be_truthy }
      end

      describe '#erased?' do
        let!(:build) { create(:ci_build, :trace, :success, :artifacts) }
        subject { build.erased? }

        context 'build has not been erased' do
          it { is_expected.to be_falsey }
        end

        context 'build has been erased' do
          before do
            build.erase
          end

          it { is_expected.to be_truthy }
        end
      end

      context 'metadata and build trace are not available' do
        let!(:build) { create(:ci_build, :success, :artifacts) }

        before do
          build.remove_artifacts_metadata!
        end

        describe '#erase' do
          it 'does not raise error' do
            expect { build.erase }.not_to raise_error
          end
        end
      end
    end
  end

  describe '#commit' do
    it 'returns commit pipeline has been created for' do
      expect(build.commit).to eq project.commit
    end
  end

  describe '#when' do
    subject { build.when }

    context 'if is undefined' do
      before do
        build.when = nil
      end

      context 'use from gitlab-ci.yml' do
        before do
          stub_ci_pipeline_yaml_file(config)
        end

        context 'if config is not found' do
          let(:config) { nil }

          it { is_expected.to eq('on_success') }
        end

        context 'if config does not have a questioned job' do
          let(:config) do
            YAML.dump({
                        test_other: {
                          script: 'Hello World'
                        }
                      })
          end

          it { is_expected.to eq('on_success') }
        end

        context 'if config has when' do
          let(:config) do
            YAML.dump({
                        test: {
                          script: 'Hello World',
                          when: 'always'
                        }
                      })
          end

          it { is_expected.to eq('always') }
        end
      end
    end
  end

  describe '#retryable?' do
    context 'when build is running' do
      before do
        build.run!
      end

      it { expect(build).not_to be_retryable }
    end

    context 'when build is finished' do
      before do
        build.success!
      end

      it { expect(build).to be_retryable }
    end
  end

  describe '#manual?' do
    before do
      build.update(when: value)
    end

    subject { build.manual? }

    context 'when is set to manual' do
      let(:value) { 'manual' }

      it { is_expected.to be_truthy }
    end

    context 'when set to something else' do
      let(:value) { 'something else' }

      it { is_expected.to be_falsey }
    end
  end

  describe '#other_actions' do
    let(:build) { create(:ci_build, :manual, pipeline: pipeline) }
    let!(:other_build) { create(:ci_build, :manual, pipeline: pipeline, name: 'other action') }

    subject { build.other_actions }

    it 'returns other actions' do
      is_expected.to contain_exactly(other_build)
    end

    context 'when build is retried' do
      let!(:new_build) { Ci::Build.retry(build) }

      it 'does not return any of them' do
        is_expected.not_to include(build, new_build)
      end
    end

    context 'when other build is retried' do
      let!(:retried_build) { Ci::Build.retry(other_build) }

      it 'returns a retried build' do
        is_expected.to contain_exactly(retried_build)
      end
    end
  end

  describe '#play' do
    let(:build) { create(:ci_build, :manual, pipeline: pipeline) }

    subject { build.play }

    it 'enques a build' do
      is_expected.to be_pending
      is_expected.to eq(build)
    end

    context 'for successful build' do
      before do
        build.update(status: 'success')
      end

      it 'creates a new build' do
        is_expected.to be_pending
        is_expected.not_to eq(build)
      end
    end
  end

  describe '#when' do
    subject { build.when }

    context 'if is undefined' do
      before do
        build.when = nil
      end

      context 'use from gitlab-ci.yml' do
        before do
          stub_ci_pipeline_yaml_file(config)
        end

        context 'if config is not found' do
          let(:config) { nil }

          it { is_expected.to eq('on_success') }
        end

        context 'if config does not have a questioned job' do
          let(:config) do
            YAML.dump({
                        test_other: {
                          script: 'Hello World'
                        }
                      })
          end

          it { is_expected.to eq('on_success') }
        end

        context 'if config has when' do
          let(:config) do
            YAML.dump({
                        test: {
                          script: 'Hello World',
                          when: 'always'
                        }
                      })
          end

          it { is_expected.to eq('always') }
        end
      end
    end
  end

  describe '#retryable?' do
    context 'when build is running' do
      before { build.run! }

      it 'returns false' do
        expect(build.retryable?).to be false
      end
    end

    context 'when build is finished' do
      before { build.success! }

      it 'returns true' do
        expect(build.retryable?).to be true
      end
    end
  end
end
