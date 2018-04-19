require 'spec_helper'

describe Ci::Build do
  set(:user) { create(:user) }
  set(:group) { create(:group, :access_requestable) }
  set(:project) { create(:project, :repository, group: group) }

  set(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: project.default_branch,
                         status: 'success')
  end

  let(:build) { create(:ci_build, pipeline: pipeline) }

  it { is_expected.to belong_to(:runner) }
  it { is_expected.to belong_to(:trigger_request) }
  it { is_expected.to belong_to(:erased_by) }
  it { is_expected.to have_many(:deployments) }
  it { is_expected.to have_many(:sourced_pipelines) }
  it { is_expected.to have_many(:trace_sections)}
  it { is_expected.to validate_presence_of(:ref) }
  it { is_expected.to respond_to(:has_trace?) }
  it { is_expected.to respond_to(:trace) }

  it { is_expected.to be_a(ArtifactMigratable) }

  describe 'associations' do
    it 'has a bidirectional relationship with projects' do
      expect(described_class.reflect_on_association(:project).has_inverse?).to eq(:builds)
      expect(Project.reflect_on_association(:builds).has_inverse?).to eq(:project)
    end
  end

  describe 'callbacks' do
    context 'when running after_create callback' do
      it 'triggers asynchronous build hooks worker' do
        expect(BuildHooksWorker).to receive(:perform_async)

        create(:ci_build)
      end
    end
  end

  describe '.manual_actions' do
    let!(:manual_but_created) { create(:ci_build, :manual, status: :created, pipeline: pipeline) }
    let!(:manual_but_succeeded) { create(:ci_build, :manual, status: :success, pipeline: pipeline) }
    let!(:manual_action) { create(:ci_build, :manual, pipeline: pipeline) }

    subject { described_class.manual_actions }

    it { is_expected.to include(manual_action) }
    it { is_expected.to include(manual_but_succeeded) }
    it { is_expected.not_to include(manual_but_created) }
  end

  describe '.ref_protected' do
    subject { described_class.ref_protected }

    context 'when protected is true' do
      let!(:job) { create(:ci_build, :protected) }

      it { is_expected.to include(job) }
    end

    context 'when protected is false' do
      let!(:job) { create(:ci_build) }

      it { is_expected.not_to include(job) }
    end

    context 'when protected is nil' do
      let!(:job) { create(:ci_build) }

      before do
        job.update_attribute(:protected, nil)
      end

      it { is_expected.not_to include(job) }
    end
  end

  describe '.with_artifacts_archive' do
    subject { described_class.with_artifacts_archive }

    context 'when job does not have an archive' do
      let!(:job) { create(:ci_build) }

      it 'does not return the job' do
        is_expected.not_to include(job)
      end
    end

    context 'when job has a legacy archive' do
      let!(:job) { create(:ci_build, :legacy_artifacts) }

      it 'returns the job' do
        is_expected.to include(job)
      end
    end

    context 'when job has a job artifact archive' do
      let!(:job) { create(:ci_build, :artifacts) }

      it 'returns the job' do
        is_expected.to include(job)
      end
    end

    context 'when job has a job artifact trace' do
      let!(:job) { create(:ci_build, :trace_artifact) }

      it 'does not return the job' do
        is_expected.not_to include(job)
      end
    end
  end

  describe '#actionize' do
    context 'when build is a created' do
      before do
        build.update_column(:status, :created)
      end

      it 'makes build a manual action' do
        expect(build.actionize).to be true
        expect(build.reload).to be_manual
      end
    end

    context 'when build is not created' do
      before do
        build.update_column(:status, :pending)
      end

      it 'does not change build status' do
        expect(build.actionize).to be false
        expect(build.reload).to be_pending
      end
    end
  end

  describe '#any_runners_online?' do
    subject { build.any_runners_online? }

    context 'when no runners' do
      it { is_expected.to be_falsey }
    end

    context 'when there are runners' do
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

  describe '#artifacts?' do
    subject { build.artifacts? }

    context 'when new artifacts are used' do
      context 'artifacts archive does not exist' do
        let(:build) { create(:ci_build) }

        it { is_expected.to be_falsy }
      end

      context 'artifacts archive exists' do
        let(:build) { create(:ci_build, :artifacts) }

        it { is_expected.to be_truthy }

        context 'is expired' do
          let(:build) { create(:ci_build, :artifacts, :expired) }

          it { is_expected.to be_falsy }
        end
      end
    end

    context 'when legacy artifacts are used' do
      let(:build) { create(:ci_build, :legacy_artifacts) }

      subject { build.artifacts? }

      context 'is expired' do
        let(:build) { create(:ci_build, :legacy_artifacts, :expired) }

        it { is_expected.to be_falsy }
      end

      context 'artifacts archive does not exist' do
        let(:build) { create(:ci_build) }

        it { is_expected.to be_falsy }
      end

      context 'artifacts archive exists' do
        let(:build) { create(:ci_build, :legacy_artifacts) }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#browsable_artifacts?' do
    subject { build.browsable_artifacts? }

    context 'artifacts metadata does not exist' do
      before do
        build.update_attributes(legacy_artifacts_metadata: nil)
      end

      it { is_expected.to be_falsy }
    end

    context 'artifacts metadata does exists' do
      let(:build) { create(:ci_build, :artifacts) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#browsable_artifacts?' do
    subject { build.browsable_artifacts? }

    context 'artifacts metadata does not exist' do
      before do
        build.update_attributes(legacy_artifacts_metadata: nil)
      end

      it { is_expected.to be_falsy }
    end

    context 'artifacts metadata does exists' do
      let(:build) { create(:ci_build, :artifacts) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#artifacts_expired?' do
    subject { build.artifacts_expired? }

    context 'is expired' do
      before do
        build.update(artifacts_expire_at: Time.now - 7.days)
      end

      it { is_expected.to be_truthy }
    end

    context 'is not expired' do
      before do
        build.update(artifacts_expire_at: Time.now + 7.days)
      end

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

  describe '#artifacts_expire_in' do
    subject { build.artifacts_expire_in }
    it { is_expected.to be_nil }

    context 'when artifacts_expire_at is specified' do
      let(:expire_at) { Time.now + 7.days }

      before do
        build.artifacts_expire_at = expire_at
      end

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

    it 'when resetting value' do
      build.artifacts_expire_in = nil

      is_expected.to be_nil
    end

    it 'when setting to 0' do
      build.artifacts_expire_in = '0'

      is_expected.to be_nil
    end
  end

  describe '#commit' do
    it 'returns commit pipeline has been created for' do
      expect(build.commit).to eq project.commit
    end
  end

  describe '#cache' do
    let(:options) { { cache: { key: "key", paths: ["public"], policy: "pull-push" } } }

    subject { build.cache }

    context 'when build has cache' do
      before do
        allow(build).to receive(:options).and_return(options)
      end

      context 'when project has jobs_cache_index' do
        before do
          allow_any_instance_of(Project).to receive(:jobs_cache_index).and_return(1)
        end

        it { is_expected.to be_an(Array).and all(include(key: "key-1")) }
      end

      context 'when project does not have jobs_cache_index' do
        before do
          allow_any_instance_of(Project).to receive(:jobs_cache_index).and_return(nil)
        end

        it { is_expected.to eq([options[:cache]]) }
      end
    end

    context 'when build does not have cache' do
      before do
        allow(build).to receive(:options).and_return({})
      end

      it { is_expected.to eq([nil]) }
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
      project.add_developer(user)

      retried_rspec = described_class.retry(rspec_test, user)

      expect(staging.depends_on_builds.map(&:id))
        .to contain_exactly(build.id, retried_rspec.id, rubocop_test.id)
    end
  end

  describe '#triggered_by?' do
    subject { build.triggered_by?(user) }

    context 'when user is owner' do
      let(:build) { create(:ci_build, pipeline: pipeline, user: user) }

      it { is_expected.to be_truthy }
    end

    context 'when user is not owner' do
      let(:another_user) { create(:user) }
      let(:build) { create(:ci_build, pipeline: pipeline, user: another_user) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#detailed_status' do
    it 'returns a detailed status' do
      expect(build.detailed_status(user))
        .to be_a Gitlab::Ci::Status::Build::Cancelable
    end
  end

  describe '#coverage_regex' do
    subject { build.coverage_regex }

    context 'when project has build_coverage_regex set' do
      let(:project_regex) { '\(\d+\.\d+\) covered' }

      before do
        project.update_column(:build_coverage_regex, project_regex)
      end

      context 'and coverage_regex attribute is not set' do
        it { is_expected.to eq(project_regex) }
      end

      context 'but coverage_regex attribute is also set' do
        let(:build_regex) { 'Code coverage: \d+\.\d+' }

        before do
          build.coverage_regex = build_regex
        end

        it { is_expected.to eq(build_regex) }
      end
    end

    context 'when neither project nor build has coverage regex set' do
      it { is_expected.to be_nil }
    end
  end

  describe '#update_coverage' do
    context "regarding coverage_regex's value," do
      before do
        build.coverage_regex = '\(\d+.\d+\%\) covered'
        build.trace.set('Coverage 1033 / 1051 LOC (98.29%) covered')
      end

      it "saves the correct extracted coverage value" do
        expect(build.update_coverage).to be(true)
        expect(build.coverage).to eq(98.29)
      end
    end
  end

  describe '#parse_trace_sections!' do
    it 'calls ExtractSectionsFromBuildTraceService' do
      expect(Ci::ExtractSectionsFromBuildTraceService)
          .to receive(:new).with(project, build.user).once.and_call_original
      expect_any_instance_of(Ci::ExtractSectionsFromBuildTraceService)
        .to receive(:execute).with(build).once

      build.parse_trace_sections!
    end
  end

  describe '#trace' do
    subject { build.trace }

    it { is_expected.to be_a(Gitlab::Ci::Trace) }
  end

  describe '#has_trace?' do
    subject { build.has_trace? }

    it "expect to call exist? method" do
      expect_any_instance_of(Gitlab::Ci::Trace).to receive(:exist?)
        .and_return(true)

      is_expected.to be(true)
    end
  end

  describe '#trace=' do
    it "expect to fail trace=" do
      expect { build.trace = "new" }.to raise_error(NotImplementedError)
    end
  end

  describe '#old_trace' do
    subject { build.old_trace }

    before do
      build.update_column(:trace, 'old trace')
    end

    it "expect to receive data from database" do
      is_expected.to eq('old trace')
    end
  end

  describe '#erase_old_trace!' do
    subject { build.send(:read_attribute, :trace) }

    before do
      build.send(:write_attribute, :trace, 'old trace')
    end

    it "expect to receive data from database" do
      build.erase_old_trace!

      is_expected.to be_nil
    end
  end

  describe '#hide_secrets' do
    let(:subject) { build.hide_secrets(data) }

    context 'hide runners token' do
      let(:data) { 'new token data'}

      before do
        build.project.update(runners_token: 'token')
      end

      it { is_expected.to eq('new xxxxx data') }
    end

    context 'hide build token' do
      let(:data) { 'new token data'}

      before do
        build.update(token: 'token')
      end

      it { is_expected.to eq('new xxxxx data') }
    end

    context 'hide build token' do
      let(:data) { 'new token data'}

      before do
        build.update(token: 'token')
      end

      it { is_expected.to eq('new xxxxx data') }
    end
  end

  describe 'deployment' do
    describe '#last_deployment' do
      subject { build.last_deployment }

      context 'when multiple deployments are created' do
        let!(:deployment1) { create(:deployment, deployable: build) }
        let!(:deployment2) { create(:deployment, deployable: build) }

        it 'returns the latest one' do
          is_expected.to eq(deployment2)
        end
      end
    end

    describe '#outdated_deployment?' do
      subject { build.outdated_deployment? }

      context 'when build succeeded' do
        let(:build) { create(:ci_build, :success) }
        let!(:deployment) { create(:deployment, deployable: build) }

        context 'current deployment is latest' do
          it { is_expected.to be_falsey }
        end

        context 'current deployment is not latest on environment' do
          let!(:deployment2) { create(:deployment, environment: deployment.environment) }

          it { is_expected.to be_truthy }
        end
      end

      context 'when build failed' do
        let(:build) { create(:ci_build, :failed) }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe 'environment' do
    describe '#has_environment?' do
      subject { build.has_environment? }

      context 'when environment is defined' do
        before do
          build.update(environment: 'review')
        end

        it { is_expected.to be_truthy }
      end

      context 'when environment is not defined' do
        before do
          build.update(environment: nil)
        end

        it { is_expected.to be_falsey }
      end
    end

    describe '#expanded_environment_name' do
      subject { build.expanded_environment_name }

      context 'when environment uses $CI_COMMIT_REF_NAME' do
        let(:build) do
          create(:ci_build,
                 ref: 'master',
                 environment: 'review/$CI_COMMIT_REF_NAME')
        end

        it { is_expected.to eq('review/master') }
      end

      context 'when environment uses yaml_variables containing symbol keys' do
        let(:build) do
          create(:ci_build,
                 yaml_variables: [{ key: :APP_HOST, value: 'host' }],
                 environment: 'review/$APP_HOST')
        end

        it { is_expected.to eq('review/host') }
      end
    end

    describe '#starts_environment?' do
      subject { build.starts_environment? }

      context 'when environment is defined' do
        before do
          build.update(environment: 'review')
        end

        context 'no action is defined' do
          it { is_expected.to be_truthy }
        end

        context 'and start action is defined' do
          before do
            build.update(options: { environment: { action: 'start' } } )
          end

          it { is_expected.to be_truthy }
        end
      end

      context 'when environment is not defined' do
        before do
          build.update(environment: nil)
        end

        it { is_expected.to be_falsey }
      end
    end

    describe '#stops_environment?' do
      subject { build.stops_environment? }

      context 'when environment is defined' do
        before do
          build.update(environment: 'review')
        end

        context 'no action is defined' do
          it { is_expected.to be_falsey }
        end

        context 'and stop action is defined' do
          before do
            build.update(options: { environment: { action: 'stop' } } )
          end

          it { is_expected.to be_truthy }
        end
      end

      context 'when environment is not defined' do
        before do
          build.update(environment: nil)
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe 'erasable build' do
    shared_examples 'erasable' do
      it 'removes artifact file' do
        expect(build.artifacts_file.exists?).to be_falsy
      end

      it 'removes artifact metadata file' do
        expect(build.artifacts_metadata.exists?).to be_falsy
      end

      it 'erases build trace in trace file' do
        expect(build).not_to have_trace
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
      context 'new artifacts' do
        let!(:build) { create(:ci_build, :trace_artifact, :success, :artifacts) }

        describe '#erase' do
          before do
            build.erase(erased_by: erased_by)
          end

          context 'erased by user' do
            let!(:erased_by) { create(:user, username: 'eraser') }

            include_examples 'erasable'

            it 'records user who erased a build' do
              expect(build.erased_by).to eq erased_by
            end
          end

          context 'erased by system' do
            let(:erased_by) { nil }

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
          let!(:build) { create(:ci_build, :trace_artifact, :success, :artifacts) }
          subject { build.erased? }

          context 'job has not been erased' do
            it { is_expected.to be_falsey }
          end

          context 'job has been erased' do
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

    context 'old artifacts' do
      context 'build is erasable' do
        context 'new artifacts' do
          let!(:build) { create(:ci_build, :trace_artifact, :success, :legacy_artifacts) }

          describe '#erase' do
            before do
              build.erase(erased_by: erased_by)
            end

            context 'erased by user' do
              let!(:erased_by) { create(:user, username: 'eraser') }

              include_examples 'erasable'

              it 'records user who erased a build' do
                expect(build.erased_by).to eq erased_by
              end
            end

            context 'erased by system' do
              let(:erased_by) { nil }

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
            let!(:build) { create(:ci_build, :trace_artifact, :success, :legacy_artifacts) }
            subject { build.erased? }

            context 'job has not been erased' do
              it { is_expected.to be_falsey }
            end

            context 'job has been erased' do
              before do
                build.erase
              end

              it { is_expected.to be_truthy }
            end
          end

          context 'metadata and build trace are not available' do
            let!(:build) { create(:ci_build, :success, :legacy_artifacts) }

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
    end
  end

  describe '#first_pending' do
    let!(:first) { create(:ci_build, pipeline: pipeline, status: 'pending', created_at: Date.yesterday) }
    let!(:second) { create(:ci_build, pipeline: pipeline, status: 'pending') }
    subject { described_class.first_pending }

    it { is_expected.to be_a(described_class) }
    it('returns with the first pending build') { is_expected.to eq(first) }
  end

  describe '#failed_but_allowed?' do
    subject { build.failed_but_allowed? }

    context 'when build is not allowed to fail' do
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

    context 'when build is allowed to fail' do
      before do
        build.allow_failure = true
      end

      context 'and build.status is success' do
        before do
          build.status = 'success'
        end

        it { is_expected.to be_falsey }
      end

      context 'and build status is failed' do
        before do
          build.status = 'failed'
        end

        it { is_expected.to be_truthy }
      end

      context 'when build is a manual action' do
        before do
          build.status = 'manual'
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe 'flags' do
    describe '#cancelable?' do
      subject { build }

      context 'when build is cancelable' do
        context 'when build is pending' do
          it { is_expected.to be_cancelable }
        end

        context 'when build is running' do
          before do
            build.run!
          end

          it { is_expected.to be_cancelable }
        end
      end

      context 'when build is not cancelable' do
        context 'when build is successful' do
          before do
            build.success!
          end

          it { is_expected.not_to be_cancelable }
        end

        context 'when build is failed' do
          before do
            build.drop!
          end

          it { is_expected.not_to be_cancelable }
        end
      end
    end

    describe '#retryable?' do
      subject { build }

      context 'when build is retryable' do
        context 'when build is successful' do
          before do
            build.success!
          end

          it { is_expected.to be_retryable }
        end

        context 'when build is failed' do
          before do
            build.drop!
          end

          it { is_expected.to be_retryable }
        end

        context 'when build is canceled' do
          before do
            build.cancel!
          end

          it { is_expected.to be_retryable }
        end
      end

      context 'when build is not retryable' do
        context 'when build is running' do
          before do
            build.run!
          end

          it { is_expected.not_to be_retryable }
        end

        context 'when build is skipped' do
          before do
            build.skip!
          end

          it { is_expected.not_to be_retryable }
        end
      end
    end

    describe '#action?' do
      before do
        build.update(when: value)
      end

      subject { build.action? }

      context 'when is set to manual' do
        let(:value) { 'manual' }

        it { is_expected.to be_truthy }
      end

      context 'when set to something else' do
        let(:value) { 'something else' }

        it { is_expected.to be_falsey }
      end
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

  describe 'build auto retry feature' do
    describe '#retries_count' do
      subject { create(:ci_build, name: 'test', pipeline: pipeline) }

      context 'when build has been retried several times' do
        before do
          create(:ci_build, :retried, name: 'test', pipeline: pipeline)
          create(:ci_build, :retried, name: 'test', pipeline: pipeline)
        end

        it 'reports a correct retry count value' do
          expect(subject.retries_count).to eq 2
        end
      end

      context 'when build has not been retried' do
        it 'returns zero' do
          expect(subject.retries_count).to eq 0
        end
      end
    end

    describe '#retries_max' do
      context 'when max retries value is defined' do
        subject { create(:ci_build, options: { retry: 1 }) }

        it 'returns a number of configured max retries' do
          expect(subject.retries_max).to eq 1
        end
      end

      context 'when max retries value is not defined' do
        subject { create(:ci_build) }

        it 'returns zero' do
          expect(subject.retries_max).to eq 0
        end
      end
    end
  end

  describe '#keep_artifacts!' do
    let(:build) { create(:ci_build, artifacts_expire_at: Time.now + 7.days) }

    subject { build.keep_artifacts! }

    it 'to reset expire_at' do
      subject

      expect(build.artifacts_expire_at).to be_nil
    end

    context 'when having artifacts files' do
      let!(:artifact) { create(:ci_job_artifact, job: build, expire_in: '7 days') }

      it 'to reset dependent objects' do
        subject

        expect(artifact.reload.expire_at).to be_nil
      end
    end
  end

  describe '#merge_request' do
    def create_mr(build, pipeline, factory: :merge_request, created_at: Time.now)
      create(factory, source_project: pipeline.project,
                      target_project: pipeline.project,
                      source_branch: build.ref,
                      created_at: created_at)
    end

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

        allow(@merge_request).to receive(:commit_shas)
          .and_return([pipeline.sha, pipeline2.sha])
        allow(MergeRequest).to receive_message_chain(:includes, :where, :reorder).and_return([@merge_request])
      end

      it 'returns the current MR' do
        expect(@build2.merge_request.id).to eq(@merge_request.id)
      end
    end
  end

  describe '#options' do
    let(:options) do
      {
        image: "ruby:2.1",
        services: [
          "postgres"
        ]
      }
    end

    it 'contains options' do
      expect(build.options).to eq(options)
    end
  end

  describe '#other_actions' do
    let(:build) { create(:ci_build, :manual, pipeline: pipeline) }
    let!(:other_build) { create(:ci_build, :manual, pipeline: pipeline, name: 'other action') }

    subject { build.other_actions }

    before do
      project.add_developer(user)
    end

    it 'returns other actions' do
      is_expected.to contain_exactly(other_build)
    end

    context 'when build is retried' do
      let!(:new_build) { described_class.retry(build, user) }

      it 'does not return any of them' do
        is_expected.not_to include(build, new_build)
      end
    end

    context 'when other build is retried' do
      let!(:retried_build) { described_class.retry(other_build, user) }

      before do
        retried_build.success
      end

      it 'returns a retried build' do
        is_expected.to contain_exactly(retried_build)
      end
    end
  end

  describe '#persisted_environment' do
    let!(:environment) do
      create(:environment, project: project, name: "foo-#{project.default_branch}")
    end

    subject { build.persisted_environment }

    context 'when referenced literally' do
      let(:build) do
        create(:ci_build, pipeline: pipeline, environment: "foo-#{project.default_branch}")
      end

      it { is_expected.to eq(environment) }
    end

    context 'when referenced with a variable' do
      let(:build) do
        create(:ci_build, pipeline: pipeline, environment: "foo-$CI_COMMIT_REF_NAME")
      end

      it { is_expected.to eq(environment) }
    end

    context 'when there is no environment' do
      it { is_expected.to be_nil }
    end
  end

  describe '#play' do
    let(:build) { create(:ci_build, :manual, pipeline: pipeline) }

    before do
      project.add_developer(user)
    end

    it 'enqueues the build' do
      expect(build.play(user)).to be_pending
    end
  end

  describe 'project settings' do
    describe '#allow_git_fetch' do
      it 'return project allow_git_fetch configuration' do
        expect(build.allow_git_fetch).to eq(project.build_allow_git_fetch)
      end
    end
  end

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

  describe '#ref_slug' do
    {
      'master'                => 'master',
      '1-foo'                 => '1-foo',
      'fix/1-foo'             => 'fix-1-foo',
      'fix-1-foo'             => 'fix-1-foo',
      'a' * 63                => 'a' * 63,
      'a' * 64                => 'a' * 63,
      'FOO'                   => 'foo',
      '-' + 'a' * 61 + '-'    => 'a' * 61,
      '-' + 'a' * 62 + '-'    => 'a' * 62,
      '-' + 'a' * 63 + '-'    => 'a' * 62,
      'a' * 62 + ' '          => 'a' * 62
    }.each do |ref, slug|
      it "transforms #{ref} to #{slug}" do
        build.ref = ref

        expect(build.ref_slug).to eq(slug)
      end
    end
  end

  describe '#repo_url' do
    subject { build.repo_url }

    it { is_expected.to be_a(String) }
    it { is_expected.to end_with(".git") }
    it { is_expected.to start_with(project.web_url[0..6]) }
    it { is_expected.to include(build.token) }
    it { is_expected.to include('gitlab-ci-token') }
    it { is_expected.to include(project.web_url[7..-1]) }
  end

  describe '#stuck?' do
    subject { build.stuck? }

    context "when commit_status.status is pending" do
      before do
        build.status = 'pending'
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

    %w[success failed canceled running].each do |state|
      context "when commit_status.status is #{state}" do
        before do
          build.status = state
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#has_expiring_artifacts?' do
    context 'when artifacts have expiration date set' do
      before do
        build.update(artifacts_expire_at: 1.day.from_now)
      end

      it 'has expiring artifacts' do
        expect(build).to have_expiring_artifacts
      end
    end

    context 'when artifacts do not have expiration date set' do
      before do
        build.update(artifacts_expire_at: nil)
      end

      it 'does not have expiring artifacts' do
        expect(build).not_to have_expiring_artifacts
      end
    end
  end

  context 'when updating the build' do
    let(:build) { create(:ci_build, artifacts_size: 23) }

    it 'updates project statistics' do
      build.artifacts_size = 42

      expect(build).to receive(:update_project_statistics_after_save).and_call_original

      expect { build.save! }
        .to change { build.project.statistics.reload.build_artifacts_size }
        .by(19)
    end

    context 'when the artifact size stays the same' do
      it 'does not update project statistics' do
        build.name = 'changed'

        expect(build).not_to receive(:update_project_statistics_after_save)

        build.save!
      end
    end
  end

  context 'when destroying the build' do
    let!(:build) { create(:ci_build, artifacts_size: 23) }

    it 'updates project statistics' do
      expect(ProjectStatistics)
        .to receive(:increment_statistic)
        .and_call_original

      expect { build.destroy! }
        .to change { build.project.statistics.reload.build_artifacts_size }
        .by(-23)
    end

    context 'when the build is destroyed due to the project being destroyed' do
      it 'does not update the project statistics' do
        expect(ProjectStatistics)
          .not_to receive(:increment_statistic)

        build.project.update_attributes(pending_delete: true)
        build.project.destroy!
      end
    end
  end

  describe '#when' do
    subject { build.when }

    context 'when `when` is undefined' do
      before do
        build.when = nil
      end

      context 'use from gitlab-ci.yml' do
        let(:project) { create(:project, :repository) }
        let(:pipeline) { create(:ci_pipeline, project: project) }

        before do
          stub_ci_pipeline_yaml_file(config)
        end

        context 'when config is not found' do
          let(:config) { nil }

          it { is_expected.to eq('on_success') }
        end

        context 'when config does not have a questioned job' do
          let(:config) do
            YAML.dump({
              test_other: {
                script: 'Hello World'
              }
            })
          end

          it { is_expected.to eq('on_success') }
        end

        context 'when config has `when`' do
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

  describe '#variables' do
    let(:container_registry_enabled) { false }
    let(:predefined_variables) do
      [
        { key: 'CI_JOB_ID', value: build.id.to_s, public: true },
        { key: 'CI_JOB_TOKEN', value: build.token, public: false },
        { key: 'CI_BUILD_ID', value: build.id.to_s, public: true },
        { key: 'CI_BUILD_TOKEN', value: build.token, public: false },
        { key: 'CI_REGISTRY_USER', value: 'gitlab-ci-token', public: true },
        { key: 'CI_REGISTRY_PASSWORD', value: build.token, public: false },
        { key: 'CI_REPOSITORY_URL', value: build.repo_url, public: false },
        { key: 'CI', value: 'true', public: true },
        { key: 'GITLAB_CI', value: 'true', public: true },
        { key: 'GITLAB_FEATURES', value: project.licensed_features.join(','), public: true },
        { key: 'CI_SERVER_NAME', value: 'GitLab', public: true },
        { key: 'CI_SERVER_VERSION', value: Gitlab::VERSION, public: true },
        { key: 'CI_SERVER_REVISION', value: Gitlab::REVISION, public: true },
        { key: 'CI_JOB_NAME', value: 'test', public: true },
        { key: 'CI_JOB_STAGE', value: 'test', public: true },
        { key: 'CI_COMMIT_SHA', value: build.sha, public: true },
        { key: 'CI_COMMIT_REF_NAME', value: build.ref, public: true },
        { key: 'CI_COMMIT_REF_SLUG', value: build.ref_slug, public: true },
        { key: 'CI_BUILD_REF', value: build.sha, public: true },
        { key: 'CI_BUILD_BEFORE_SHA', value: build.before_sha, public: true },
        { key: 'CI_BUILD_REF_NAME', value: build.ref, public: true },
        { key: 'CI_BUILD_REF_SLUG', value: build.ref_slug, public: true },
        { key: 'CI_BUILD_NAME', value: 'test', public: true },
        { key: 'CI_BUILD_STAGE', value: 'test', public: true },
        { key: 'CI_PROJECT_ID', value: project.id.to_s, public: true },
        { key: 'CI_PROJECT_NAME', value: project.path, public: true },
        { key: 'CI_PROJECT_PATH', value: project.full_path, public: true },
        { key: 'CI_PROJECT_PATH_SLUG', value: project.full_path_slug, public: true },
        { key: 'CI_PROJECT_NAMESPACE', value: project.namespace.full_path, public: true },
        { key: 'CI_PROJECT_URL', value: project.web_url, public: true },
        { key: 'CI_PROJECT_VISIBILITY', value: 'private', public: true },
        { key: 'CI_PIPELINE_ID', value: pipeline.id.to_s, public: true },
        { key: 'CI_CONFIG_PATH', value: pipeline.ci_yaml_file_path, public: true },
        { key: 'CI_PIPELINE_SOURCE', value: pipeline.source, public: true }
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

      it { is_expected.to include(*predefined_variables) }
    end

    context 'when build has user' do
      let(:user_variables) do
        [
          { key: 'GITLAB_USER_ID', value: user.id.to_s, public: true },
          { key: 'GITLAB_USER_EMAIL', value: user.email, public: true },
          { key: 'GITLAB_USER_LOGIN', value: user.username, public: true },
          { key: 'GITLAB_USER_NAME', value: user.name, public: true }
        ]
      end

      before do
        build.update_attributes(user: user)
      end

      it { user_variables.each { |v| is_expected.to include(v) } }
    end

    context 'when build has an environment' do
      let(:environment_variables) do
        [
          { key: 'CI_ENVIRONMENT_NAME', value: 'production', public: true },
          { key: 'CI_ENVIRONMENT_SLUG', value: 'prod-slug',  public: true }
        ]
      end

      let!(:environment) do
        create(:environment,
               project: build.project,
               name: 'production',
               slug: 'prod-slug',
               external_url: '')
      end

      before do
        build.update(environment: 'production')
      end

      shared_examples 'containing environment variables' do
        it { environment_variables.each { |v| is_expected.to include(v) } }
      end

      context 'when no URL was set' do
        it_behaves_like 'containing environment variables'

        it 'does not have CI_ENVIRONMENT_URL' do
          keys = subject.map { |var| var[:key] }

          expect(keys).not_to include('CI_ENVIRONMENT_URL')
        end
      end

      context 'when an URL was set' do
        let(:url) { 'http://host/test' }

        before do
          environment_variables <<
            { key: 'CI_ENVIRONMENT_URL', value: url, public: true }
        end

        context 'when the URL was set from the job' do
          before do
            build.update(options: { environment: { url: url } })
          end

          it_behaves_like 'containing environment variables'

          context 'when variables are used in the URL, it does not expand' do
            let(:url) { 'http://$CI_PROJECT_NAME-$CI_ENVIRONMENT_SLUG' }

            it_behaves_like 'containing environment variables'

            it 'puts $CI_ENVIRONMENT_URL in the last so all other variables are available to be used when runners are trying to expand it' do
              expect(subject.last).to eq(environment_variables.last)
            end
          end
        end

        context 'when the URL was not set from the job, but environment' do
          before do
            environment.update(external_url: url)
          end

          it_behaves_like 'containing environment variables'
        end
      end
    end

    context 'when build started manually' do
      before do
        build.update_attributes(when: :manual)
      end

      let(:manual_variable) do
        { key: 'CI_JOB_MANUAL', value: 'true', public: true }
      end

      it { is_expected.to include(manual_variable) }
    end

    context 'when build is for tag' do
      let(:tag_variable) do
        { key: 'CI_COMMIT_TAG', value: 'master', public: true }
      end

      before do
        build.update_attributes(tag: true)
      end

      it { is_expected.to include(tag_variable) }
    end

    context 'when secret variable is defined' do
      let(:secret_variable) do
        { key: 'SECRET_KEY', value: 'secret_value', public: false }
      end

      before do
        create(:ci_variable,
               secret_variable.slice(:key, :value).merge(project: project))
      end

      it { is_expected.to include(secret_variable) }
    end

    context 'when protected variable is defined' do
      let(:protected_variable) do
        { key: 'PROTECTED_KEY', value: 'protected_value', public: false }
      end

      before do
        create(:ci_variable,
               :protected,
               protected_variable.slice(:key, :value).merge(project: project))
      end

      context 'when the branch is protected' do
        before do
          allow(build.project).to receive(:protected_for?).with(build.ref).and_return(true)
        end

        it { is_expected.to include(protected_variable) }
      end

      context 'when the tag is protected' do
        before do
          allow(build.project).to receive(:protected_for?).with(build.ref).and_return(true)
        end

        it { is_expected.to include(protected_variable) }
      end

      context 'when the ref is not protected' do
        it { is_expected.not_to include(protected_variable) }
      end
    end

    context 'when group secret variable is defined' do
      let(:secret_variable) do
        { key: 'SECRET_KEY', value: 'secret_value', public: false }
      end

      before do
        create(:ci_group_variable,
               secret_variable.slice(:key, :value).merge(group: group))
      end

      it { is_expected.to include(secret_variable) }
    end

    context 'when group protected variable is defined' do
      let(:protected_variable) do
        { key: 'PROTECTED_KEY', value: 'protected_value', public: false }
      end

      before do
        create(:ci_group_variable,
               :protected,
               protected_variable.slice(:key, :value).merge(group: group))
      end

      context 'when the branch is protected' do
        before do
          allow(build.project).to receive(:protected_for?).with(build.ref).and_return(true)
        end

        it { is_expected.to include(protected_variable) }
      end

      context 'when the tag is protected' do
        before do
          allow(build.project).to receive(:protected_for?).with(build.ref).and_return(true)
        end

        it { is_expected.to include(protected_variable) }
      end

      context 'when the ref is not protected' do
        before do
          build.update_column(:ref, 'some/feature')
        end

        it { is_expected.not_to include(protected_variable) }
      end
    end

    context 'when build is for triggers' do
      let(:trigger) { create(:ci_trigger, project: project) }
      let(:trigger_request) { create(:ci_trigger_request, pipeline: pipeline, trigger: trigger) }

      let(:user_trigger_variable) do
        { key: 'TRIGGER_KEY_1', value: 'TRIGGER_VALUE_1', public: false }
      end

      let(:predefined_trigger_variable) do
        { key: 'CI_PIPELINE_TRIGGERED', value: 'true', public: true }
      end

      before do
        build.trigger_request = trigger_request
      end

      shared_examples 'returns variables for triggers' do
        it { is_expected.to include(user_trigger_variable) }
        it { is_expected.to include(predefined_trigger_variable) }
      end

      context 'when variables are stored in trigger_request' do
        before do
          trigger_request.update_attribute(:variables, { 'TRIGGER_KEY_1' => 'TRIGGER_VALUE_1' } )
        end

        it_behaves_like 'returns variables for triggers'
      end

      context 'when variables are stored in pipeline_variables' do
        before do
          create(:ci_pipeline_variable, pipeline: pipeline, key: 'TRIGGER_KEY_1', value: 'TRIGGER_VALUE_1')
        end

        it_behaves_like 'returns variables for triggers'
      end
    end

    context 'when pipeline has a variable' do
      let!(:pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline) }

      it { is_expected.to include(pipeline_variable.to_runner_variable) }
    end

    context 'when a job was triggered by a pipeline schedule' do
      let(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project) }

      let!(:pipeline_schedule_variable) do
        create(:ci_pipeline_schedule_variable,
               key: 'SCHEDULE_VARIABLE_KEY',
               pipeline_schedule: pipeline_schedule)
      end

      before do
        pipeline_schedule.pipelines << pipeline
        pipeline_schedule.reload
      end

      it { is_expected.to include(pipeline_schedule_variable.to_runner_variable) }
    end

    context 'when yaml_variables are undefined' do
      let(:pipeline) { create(:ci_pipeline, project: project) }

      before do
        build.yaml_variables = nil
      end

      context 'use from gitlab-ci.yml' do
        before do
          stub_ci_pipeline_yaml_file(config)
        end

        context 'when config is not found' do
          let(:config) { nil }

          it { is_expected.to include(*predefined_variables) }
        end

        context 'when config does not have a questioned job' do
          let(:config) do
            YAML.dump({
              test_other: {
                script: 'Hello World'
              }
            })
          end

          it { is_expected.to include(*predefined_variables) }
        end

        context 'when config has variables' do
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
            [{ key: 'KEY', value: 'value', public: true }]
          end

          it { is_expected.to include(*predefined_variables) }
          it { is_expected.to include(*variables) }
        end
      end
    end

    context 'when container registry is enabled' do
      let(:container_registry_enabled) { true }
      let(:ci_registry) do
        { key: 'CI_REGISTRY',  value: 'registry.example.com',  public: true }
      end
      let(:ci_registry_image) do
        { key: 'CI_REGISTRY_IMAGE',  value: project.container_registry_url, public: true }
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
      let(:runner) { create(:ci_runner, description: 'description', tag_list: %w(docker linux)) }

      before do
        build.update(runner: runner)
      end

      it { is_expected.to include({ key: 'CI_RUNNER_ID', value: runner.id.to_s, public: true }) }
      it { is_expected.to include({ key: 'CI_RUNNER_DESCRIPTION', value: 'description', public: true }) }
      it { is_expected.to include({ key: 'CI_RUNNER_TAGS', value: 'docker, linux', public: true }) }
    end

    context 'when build is for a deployment' do
      let(:deployment_variable) { { key: 'KUBERNETES_TOKEN', value: 'TOKEN', public: false } }

      before do
        build.environment = 'production'

        allow_any_instance_of(Project)
          .to receive(:deployment_variables)
          .and_return([deployment_variable])
      end

      it { is_expected.to include(deployment_variable) }
    end

    context 'when project has custom CI config path' do
      let(:ci_config_path) { { key: 'CI_CONFIG_PATH', value: 'custom', public: true } }

      before do
        project.update(ci_config_path: 'custom')
      end

      it { is_expected.to include(ci_config_path) }
    end

    context 'when using auto devops' do
      context 'and is enabled' do
        before do
          project.create_auto_devops!(enabled: true, domain: 'example.com')
        end

        it "includes AUTO_DEVOPS_DOMAIN" do
          is_expected.to include(
            { key: 'AUTO_DEVOPS_DOMAIN', value: 'example.com', public: true })
        end
      end

      context 'and is disabled' do
        before do
          project.create_auto_devops!(enabled: false, domain: 'example.com')
        end

        it "includes AUTO_DEVOPS_DOMAIN" do
          is_expected.not_to include(
            { key: 'AUTO_DEVOPS_DOMAIN', value: 'example.com', public: true })
        end
      end
    end

    context 'when pipeline variable overrides build variable' do
      before do
        build.yaml_variables = [{ key: 'MYVAR', value: 'myvar', public: true }]
        pipeline.variables.build(key: 'MYVAR', value: 'pipeline value')
      end

      it 'overrides YAML variable using a pipeline variable' do
        variables = subject.reverse.uniq { |variable| variable[:key] }.reverse

        expect(variables)
          .not_to include(key: 'MYVAR', value: 'myvar', public: true)
        expect(variables)
          .to include(key: 'MYVAR', value: 'pipeline value', public: false)
      end
    end

    describe 'variables ordering' do
      context 'when variables hierarchy is stubbed' do
        let(:build_pre_var) { { key: 'build', value: 'value', public: true } }
        let(:project_pre_var) { { key: 'project', value: 'value', public: true } }
        let(:pipeline_pre_var) { { key: 'pipeline', value: 'value', public: true } }
        let(:build_yaml_var) { { key: 'yaml', value: 'value', public: true } }

        before do
          allow(build).to receive(:predefined_variables) { [build_pre_var] }
          allow(build).to receive(:yaml_variables) { [build_yaml_var] }
          allow(build).to receive(:persisted_variables) { [] }

          allow_any_instance_of(Project)
            .to receive(:predefined_variables) { [project_pre_var] }

          allow_any_instance_of(EE::Project)
            .to receive(:secret_variables_for)
            .with(ref: 'master', environment: nil) do
            [create(:ci_variable, key: 'secret', value: 'value')]
          end

          allow_any_instance_of(Ci::Pipeline)
            .to receive(:predefined_variables) { [pipeline_pre_var] }
        end

        it 'returns variables in order depending on resource hierarchy' do
          is_expected.to eq(
            [build_pre_var,
             project_pre_var,
             pipeline_pre_var,
             build_yaml_var,
             { key: 'secret', value: 'value', public: false }])
        end
      end

      context 'when build has environment and user-provided variables' do
        let(:expected_variables) do
          predefined_variables.map { |variable| variable.fetch(:key) } +
            %w[YAML_VARIABLE CI_ENVIRONMENT_NAME CI_ENVIRONMENT_SLUG
               CI_ENVIRONMENT_URL]
        end

        before do
          create(:environment, project: build.project,
                               name: 'staging')

          build.yaml_variables = [{ key: 'YAML_VARIABLE',
                                    value: 'var',
                                    public: true }]
          build.environment = 'staging'
        end

        it 'matches explicit variables ordering' do
          received_variables = subject.map { |variable| variable.fetch(:key) }

          expect(received_variables).to eq expected_variables
        end
      end
    end

    context 'when build has not been persisted yet' do
      let(:build) do
        described_class.new(
          name: 'rspec',
          stage: 'test',
          ref: 'feature',
          project: project,
          pipeline: pipeline
        )
      end

      it 'returns static predefined variables' do
        expect(build.variables.size).to be >= 28
        expect(build.variables)
          .to include(key: 'CI_COMMIT_REF_NAME', value: 'feature', public: true)
        expect(build).not_to be_persisted
      end
    end

    context 'for deploy tokens' do
      let(:deploy_token) { create(:deploy_token, :gitlab_deploy_token) }

      let(:deploy_token_variables) do
        [
          { key: 'CI_DEPLOY_USER', value: deploy_token.name, public: true },
          { key: 'CI_DEPLOY_PASSWORD', value: deploy_token.token, public: true }
        ]
      end

      context 'when gitlab-deploy-token exists' do
        before do
          project.deploy_tokens << deploy_token
        end

        it 'should include deploy token variables' do
          is_expected.to include(*deploy_token_variables)
        end
      end

      context 'when gitlab-deploy-token does not exist' do
        it 'should not include deploy token variables' do
          expect(subject.find { |v| v[:key] == 'CI_DEPLOY_USER'}).to be_nil
          expect(subject.find { |v| v[:key] == 'CI_DEPLOY_PASSWORD'}).to be_nil
        end
      end
    end
  end

  describe '#scoped_variables' do
    context 'when build has not been persisted yet' do
      let(:build) do
        described_class.new(
          name: 'rspec',
          stage: 'test',
          ref: 'feature',
          project: project,
          pipeline: pipeline
        )
      end

      it 'does not persist the build' do
        expect(build).to be_valid
        expect(build).not_to be_persisted

        build.scoped_variables

        expect(build).not_to be_persisted
      end

      it 'returns static predefined variables' do
        keys = %w[CI_JOB_NAME
                  CI_COMMIT_SHA
                  CI_COMMIT_REF_NAME
                  CI_COMMIT_REF_SLUG
                  CI_JOB_STAGE]

        variables = build.scoped_variables

        variables.map { |env| env[:key] }.tap do |names|
          expect(names).to include(*keys)
        end

        expect(variables)
          .to include(key: 'CI_COMMIT_REF_NAME', value: 'feature', public: true)
      end

      it 'does not return prohibited variables' do
        keys = %w[CI_JOB_ID
                  CI_JOB_TOKEN
                  CI_BUILD_ID
                  CI_BUILD_TOKEN
                  CI_REGISTRY_USER
                  CI_REGISTRY_PASSWORD
                  CI_REPOSITORY_URL
                  CI_ENVIRONMENT_URL
                  CI_DEPLOY_USER
                  CI_DEPLOY_PASSWORD]

        build.scoped_variables.map { |env| env[:key] }.tap do |names|
          expect(names).not_to include(*keys)
        end
      end
    end
  end

  describe '#scoped_variables_hash' do
    context 'when overriding secret variables' do
      before do
        project.variables.create!(key: 'MY_VAR', value: 'my value 1')
        pipeline.variables.create!(key: 'MY_VAR', value: 'my value 2')
      end

      it 'returns a regular hash created using valid ordering' do
        expect(build.scoped_variables_hash).to include('MY_VAR': 'my value 2')
        expect(build.scoped_variables_hash).not_to include('MY_VAR': 'my value 1')
      end
    end

    context 'when overriding user-provided variables' do
      before do
        pipeline.variables.build(key: 'MY_VAR', value: 'pipeline value')
        build.yaml_variables = [{ key: 'MY_VAR', value: 'myvar', public: true }]
      end

      it 'returns a hash including variable with higher precedence' do
        expect(build.scoped_variables_hash).to include('MY_VAR': 'pipeline value')
        expect(build.scoped_variables_hash).not_to include('MY_VAR': 'myvar')
      end
    end
  end

  describe 'state transition: any => [:pending]' do
    let(:build) { create(:ci_build, :created) }

    it 'queues BuildQueueWorker' do
      expect(BuildQueueWorker).to receive(:perform_async).with(build.id)

      build.enqueue
    end
  end

  describe 'state transition: pending: :running' do
    let(:runner) { create(:ci_runner) }
    let(:job) { create(:ci_build, :pending, runner: runner) }

    before do
      job.project.update_attribute(:build_timeout, 1800)
    end

    def run_job_without_exception
      job.run!
    rescue StateMachines::InvalidTransition
    end

    shared_examples 'saves data on transition' do
      it 'saves timeout' do
        expect { job.run! }.to change { job.reload.ensure_metadata.timeout }.from(nil).to(expected_timeout)
      end

      it 'saves timeout_source' do
        expect { job.run! }.to change { job.reload.ensure_metadata.timeout_source }.from('unknown_timeout_source').to(expected_timeout_source)
      end

      context 'when Ci::BuildMetadata#update_timeout_state fails update' do
        before do
          allow_any_instance_of(Ci::BuildMetadata).to receive(:update_timeout_state).and_return(false)
        end

        it "doesn't save timeout" do
          expect { run_job_without_exception }.not_to change { job.reload.ensure_metadata.timeout_source }
        end

        it "doesn't save timeout_source" do
          expect { run_job_without_exception }.not_to change { job.reload.ensure_metadata.timeout_source }
        end
      end
    end

    context 'when runner timeout overrides project timeout' do
      let(:expected_timeout) { 900 }
      let(:expected_timeout_source) { 'runner_timeout_source' }

      before do
        runner.update_attribute(:maximum_timeout, 900)
      end

      it_behaves_like 'saves data on transition'
    end

    context "when runner timeout doesn't override project timeout" do
      let(:expected_timeout) { 1800 }
      let(:expected_timeout_source) { 'project_timeout_source' }

      before do
        runner.update_attribute(:maximum_timeout, 3600)
      end

      it_behaves_like 'saves data on transition'
    end
  end

  describe 'state transition: any => [:running]' do
    shared_examples 'validation is active' do
      context 'when depended job has not been completed yet' do
        let!(:pre_stage_job) { create(:ci_build, :manual, pipeline: pipeline, name: 'test', stage_idx: 0) }

        it { expect { job.run! }.not_to raise_error }
      end

      context 'when artifacts of depended job has been expired' do
        let!(:pre_stage_job) { create(:ci_build, :success, :expired, pipeline: pipeline, name: 'test', stage_idx: 0) }

        it { expect { job.run! }.to raise_error(Ci::Build::MissingDependenciesError) }
      end

      context 'when artifacts of depended job has been erased' do
        let!(:pre_stage_job) { create(:ci_build, :success, pipeline: pipeline, name: 'test', stage_idx: 0, erased_at: 1.minute.ago) }

        before do
          pre_stage_job.erase
        end

        it { expect { job.run! }.to raise_error(Ci::Build::MissingDependenciesError) }
      end
    end

    shared_examples 'validation is not active' do
      context 'when depended job has not been completed yet' do
        let!(:pre_stage_job) { create(:ci_build, :manual, pipeline: pipeline, name: 'test', stage_idx: 0) }

        it { expect { job.run! }.not_to raise_error }
      end
      context 'when artifacts of depended job has been expired' do
        let!(:pre_stage_job) { create(:ci_build, :success, :expired, pipeline: pipeline, name: 'test', stage_idx: 0) }

        it { expect { job.run! }.not_to raise_error }
      end

      context 'when artifacts of depended job has been erased' do
        let!(:pre_stage_job) { create(:ci_build, :success, pipeline: pipeline, name: 'test', stage_idx: 0, erased_at: 1.minute.ago) }

        before do
          pre_stage_job.erase
        end

        it { expect { job.run! }.not_to raise_error }
      end
    end

    let!(:job) { create(:ci_build, :pending, pipeline: pipeline, stage_idx: 1, options: options) }

    context 'when validates for dependencies is enabled' do
      before do
        stub_feature_flags(ci_disable_validates_dependencies: false)
      end

      let!(:pre_stage_job) { create(:ci_build, :success, pipeline: pipeline, name: 'test', stage_idx: 0) }

      context 'when "dependencies" keyword is not defined' do
        let(:options) { {} }

        it { expect { job.run! }.not_to raise_error }
      end

      context 'when "dependencies" keyword is empty' do
        let(:options) { { dependencies: [] } }

        it { expect { job.run! }.not_to raise_error }
      end

      context 'when "dependencies" keyword is specified' do
        let(:options) { { dependencies: ['test'] } }

        it_behaves_like 'validation is active'
      end
    end

    context 'when validates for dependencies is disabled' do
      let(:options) { { dependencies: ['test'] } }

      before do
        stub_feature_flags(ci_disable_validates_dependencies: true)
      end

      it_behaves_like 'validation is not active'
    end
  end

  describe 'state transition when build fails' do
    let(:service) { MergeRequests::AddTodoWhenBuildFailsService.new(project, user) }

    before do
      allow(MergeRequests::AddTodoWhenBuildFailsService).to receive(:new).and_return(service)
      allow(service).to receive(:close)
    end

    context 'when build is configured to be retried' do
      subject { create(:ci_build, :running, options: { retry: 3 }, project: project, user: user) }

      it 'retries build and assigns the same user to it' do
        expect(described_class).to receive(:retry)
          .with(subject, user)

        subject.drop!
      end

      it 'does not try to create a todo' do
        project.add_developer(user)

        expect(service).not_to receive(:commit_status_merge_requests)

        subject.drop!
      end

      context 'when retry service raises Gitlab::Access::AccessDeniedError exception' do
        let(:retry_service) { Ci::RetryBuildService.new(subject.project, subject.user) }

        before do
          allow_any_instance_of(Ci::RetryBuildService)
            .to receive(:execute)
            .with(subject)
            .and_raise(Gitlab::Access::AccessDeniedError)
          allow(Rails.logger).to receive(:error)
        end

        it 'handles raised exception' do
          expect { subject.drop! }.not_to raise_exception(Gitlab::Access::AccessDeniedError)
        end

        it 'logs the error' do
          subject.drop!

          expect(Rails.logger)
            .to have_received(:error)
            .with(a_string_matching("Unable to auto-retry job #{subject.id}"))
        end

        it 'fails the job' do
          subject.drop!
          expect(subject.failed?).to be_truthy
        end
      end
    end

    context 'when build is not configured to be retried' do
      subject { create(:ci_build, :running, project: project, user: user) }

      it 'does not retry build' do
        expect(described_class).not_to receive(:retry)

        subject.drop!
      end

      it 'does not count retries when not necessary' do
        expect(described_class).not_to receive(:retry)
        expect_any_instance_of(described_class)
          .not_to receive(:retries_count)

        subject.drop!
      end

      it 'creates a todo' do
        project.add_developer(user)

        expect(service).to receive(:commit_status_merge_requests)

        subject.drop!
      end
    end
  end

  describe '.matches_tag_ids' do
    set(:build) { create(:ci_build, project: project, user: user) }
    let(:tag_ids) { ::ActsAsTaggableOn::Tag.named_any(tag_list).ids }

    subject { described_class.where(id: build).matches_tag_ids(tag_ids) }

    before do
      build.update(tag_list: build_tag_list)
    end

    context 'when have different tags' do
      let(:build_tag_list) { %w(A B) }
      let(:tag_list) { %w(C D) }

      it "does not match a build" do
        is_expected.not_to contain_exactly(build)
      end
    end

    context 'when have a subset of tags' do
      let(:build_tag_list) { %w(A B) }
      let(:tag_list) { %w(A B C D) }

      it "does match a build" do
        is_expected.to contain_exactly(build)
      end
    end

    context 'when build does not have tags' do
      let(:build_tag_list) { [] }
      let(:tag_list) { %w(C D) }

      it "does match a build" do
        is_expected.to contain_exactly(build)
      end
    end

    context 'when does not have a subset of tags' do
      let(:build_tag_list) { %w(A B C) }
      let(:tag_list) { %w(C D) }

      it "does not match a build" do
        is_expected.not_to contain_exactly(build)
      end
    end
  end

  describe '.matches_tags' do
    set(:build) { create(:ci_build, project: project, user: user) }

    subject { described_class.where(id: build).with_any_tags }

    before do
      build.update(tag_list: tag_list)
    end

    context 'when does have tags' do
      let(:tag_list) { %w(A B) }

      it "does match a build" do
        is_expected.to contain_exactly(build)
      end
    end

    context 'when does not have tags' do
      let(:tag_list) { [] }

      it "does not match a build" do
        is_expected.not_to contain_exactly(build)
      end
    end
  end
end
