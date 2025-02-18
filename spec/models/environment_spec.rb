# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environment, :use_clean_rails_memory_store_caching, feature_category: :continuous_delivery do
  include ReactiveCachingHelpers
  using RSpec::Parameterized::TableSyntax
  include RepoHelpers
  include StubENV
  include CreateEnvironmentsHelpers

  let(:project) { create(:project, :repository) }

  subject(:environment) { create(:environment, project: project) }

  it { is_expected.to be_kind_of(ReactiveCaching) }
  it { is_expected.to nullify_if_blank(:external_url) }
  it { is_expected.to nullify_if_blank(:kubernetes_namespace) }
  it { is_expected.to nullify_if_blank(:flux_resource_path) }
  it { is_expected.to nullify_if_blank(:description) }

  it { is_expected.to belong_to(:project).required }
  it { is_expected.to belong_to(:merge_request).optional }
  it { is_expected.to belong_to(:cluster_agent).optional }

  it { is_expected.to have_many(:deployments) }
  it { is_expected.to have_many(:alert_management_alerts) }
  it { is_expected.to have_one(:upcoming_deployment) }
  it { is_expected.to have_one(:latest_opened_most_severe_alert) }

  it { is_expected.to delegate_method(:manual_actions).to(:last_deployment) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
  it { is_expected.to validate_length_of(:name).is_at_most(255) }

  it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:project_id) }
  it { is_expected.to validate_length_of(:slug).is_at_most(24) }

  it { is_expected.to validate_length_of(:external_url).is_at_most(255) }
  it { is_expected.to validate_length_of(:kubernetes_namespace).is_at_most(63) }
  it { is_expected.to validate_length_of(:flux_resource_path).is_at_most(255) }
  it { is_expected.to validate_length_of(:description).is_at_most(10000) }
  it { is_expected.to validate_length_of(:description_html).is_at_most(50000) }

  describe 'validation' do
    it 'does not become invalid record when external_url is empty' do
      environment = build(:environment, external_url: nil)

      expect(environment).to be_valid
    end

    context 'does not allow changes to merge_request' do
      let(:merge_request) { create(:merge_request, source_project: project) }

      it 'for an environment that has no merge request associated' do
        environment = create(:environment)

        environment.merge_request = merge_request

        expect(environment).not_to be_valid
      end

      it 'for an environment that has a merge request associated' do
        environment = create(:environment, merge_request: merge_request)

        environment.merge_request = nil

        expect(environment).not_to be_valid
      end
    end

    context 'tier' do
      let!(:env) { build(:environment, tier: nil) }

      before do
        # Disable `before_validation: :ensure_environment_tier` since it always set tier and interfere with tests.
        # See: https://github.com/thoughtbot/shoulda/issues/178#issuecomment-1654014

        allow_any_instance_of(described_class).to receive(:ensure_environment_tier).and_return(env)
      end

      context 'presence is checked' do
        it 'during create and update' do
          expect(env).to validate_presence_of(:tier).on(:create)
          expect(env).to validate_presence_of(:tier).on(:update)
        end
      end
    end

    context 'with cluster agent related fields' do
      let(:cluster_agent) { create(:cluster_agent, project: project) }

      it 'fails when configuring kubernetes namespace without cluster agent is invalid' do
        environment.kubernetes_namespace = 'default'

        environment.valid?

        expect(environment.errors[:kubernetes_namespace].first).to eq('cannot be set without a cluster agent')
      end

      it 'fails when configuring flux resource path without kubernetes namespace is invalid' do
        environment.cluster_agent_id = cluster_agent.id
        environment.flux_resource_path = 'HelmRelease/default'

        environment.valid?

        expect(environment.errors[:flux_resource_path].first).to eq('cannot be set without a kubernetes namespace')
      end
    end
  end

  describe 'validate and sanitize external url' do
    let_it_be_with_refind(:environment) { create(:environment) }

    where(:source_external_url, :expected_error_message) do
      nil                                              | nil
      'http://example.com'                             | nil
      'example.com'                                    | nil
      'www.example.io'                                 | nil
      'http://$URL'                                    | nil
      'http://$(URL)'                                  | nil
      'custom://example.com'                           | nil
      '1.1.1.1'                                        | nil
      '$BASE_URL/${CI_COMMIT_REF_NAME}'                | nil
      '$ENVIRONMENT_URL'                               | nil
      'https://$SUB.$MAIN'                             | nil
      'https://$SUB-$REGION.$MAIN'                     | nil
      'https://example.com?param={()}'                 | nil
      'http://XSS?x=<script>alert(1)</script>'         | nil
      'https://user:${VARIABLE}@example.io'            | nil
      'https://example.com/test?param={data}'          | nil
      'http://${URL}'                                  | 'URI is invalid'
      'https://${URL}.example/test'                    | 'URI is invalid'
      'http://test${CI_MERGE_REQUEST_IID}.example.com' | 'URI is invalid'
      'javascript:alert("hello")'                      | 'javascript scheme is not allowed'
    end
    with_them do
      it 'sets an external URL or an error' do
        environment.external_url = source_external_url

        environment.valid?

        if expected_error_message
          expect(environment.errors[:external_url].first).to eq(expected_error_message)
        else
          expect(environment.errors[:external_url]).to be_empty,
            "There were unexpected errors: #{environment.errors.full_messages}"
          expect(environment.external_url).to eq(source_external_url)
        end
      end
    end
  end

  describe '.before_save' do
    it 'ensures environment tier when a new object is created' do
      environment = build(:environment, name: 'gprd', tier: nil)

      expect { environment.save! }.to change { environment.tier }.from(nil).to('production')
    end

    it 'ensures environment tier when an existing object is updated' do
      environment = create(:environment, name: 'gprd')
      environment.update_column(:tier, nil)

      expect { environment.save! }.to change { environment.reload.tier }.from(nil).to('production')
    end

    it 'does not overwrite the existing environment tier' do
      environment = create(:environment, name: 'gprd', tier: :production)

      expect { environment.update!(name: 'gstg') }.not_to change { environment.reload.tier }
    end
  end

  describe '.order_by_last_deployed_at' do
    let!(:environment1) { create(:environment, project: project) }
    let!(:environment2) { create(:environment, project: project) }
    let!(:environment3) { create(:environment, project: project) }
    let!(:deployment1) { create(:deployment, environment: environment1) }
    let!(:deployment2) { create(:deployment, environment: environment2) }
    let!(:deployment3) { create(:deployment, environment: environment1) }

    it 'returns the environments in ascending order of having been last deployed' do
      expect(project.environments.order_by_last_deployed_at.to_a).to eq([environment3, environment2, environment1])
    end

    it 'returns the environments in descending order of having been last deployed' do
      expect(project.environments.order_by_last_deployed_at_desc.to_a).to eq([environment1, environment2, environment3])
    end
  end

  describe '#long_stopping?' do
    subject { environment1.long_stopping? }

    let(:long_ago) { (described_class::LONG_STOP + 1.day).ago }
    let(:not_long_ago) { (described_class::LONG_STOP - 1.day).ago }

    context 'when a stopping environment has not been updated recently' do
      let!(:environment1) { create(:environment, state: 'stopping', project: project, updated_at: long_ago) }

      it { is_expected.to eq(true) }
    end

    context 'when a stopping environment has been updated recently' do
      let!(:environment1) { create(:environment, state: 'stopping', project: project, updated_at: not_long_ago) }

      it { is_expected.to eq(false) }
    end

    context 'when a non stopping environment has not been updated recently' do
      let!(:environment1) { create(:environment, project: project, updated_at: long_ago) }

      it { is_expected.to eq(false) }
    end

    context 'when a non stopping environment has been updated recently' do
      let!(:environment1) { create(:environment, project: project, updated_at: not_long_ago) }

      it { is_expected.to eq(false) }
    end
  end

  describe ".stopped_review_apps" do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:old_stopped_review_env) { create(:environment, :with_review_app, :stopped, created_at: 31.days.ago, project: project) }
    let_it_be(:new_stopped_review_env) { create(:environment, :with_review_app, :stopped, project: project) }
    let_it_be(:old_active_review_env) { create(:environment, :with_review_app, :available, created_at: 31.days.ago, project: project) }
    let_it_be(:old_stopped_other_env) { create(:environment, :stopped, created_at: 31.days.ago, project: project) }
    let_it_be(:new_stopped_other_env) { create(:environment, :stopped, project: project) }
    let_it_be(:old_active_other_env) { create(:environment, :available, created_at: 31.days.ago, project: project) }

    let(:before) { 30.days.ago }
    let(:limit) { 1000 }

    subject { project.environments.stopped_review_apps(before, limit) } # rubocop: disable RSpec/SingleLineHook

    it { is_expected.to contain_exactly(old_stopped_review_env) }

    context "current timestamp" do
      let(:before) { Time.zone.now }

      it { is_expected.to contain_exactly(old_stopped_review_env, new_stopped_review_env) }
    end
  end

  describe "scheduled deletion" do
    let_it_be(:deletable_environment) { create(:environment, auto_delete_at: Time.zone.now) }
    let_it_be(:undeletable_environment) { create(:environment, auto_delete_at: nil) }

    describe ".scheduled_for_deletion" do
      subject { described_class.scheduled_for_deletion }

      it { is_expected.to contain_exactly(deletable_environment) }
    end

    describe ".not_scheduled_for_deletion" do
      subject { described_class.not_scheduled_for_deletion }

      it { is_expected.to contain_exactly(undeletable_environment) }
    end

    describe ".schedule_to_delete" do
      subject { described_class.id_in(deletable_environment).schedule_to_delete }

      it "schedules the record for deletion" do
        freeze_time do
          subject

          deletable_environment.reload
          undeletable_environment.reload

          expect(deletable_environment.auto_delete_at).to eq(1.week.from_now)
          expect(undeletable_environment.auto_delete_at).to be_nil
        end
      end
    end
  end

  describe 'state machine' do
    it 'invalidates the cache after a change' do
      expect(environment).to receive(:expire_etag_cache)

      environment.stop
    end

    it 'allows to start environment in stopping state' do
      environment.update!(state: :stopping)

      environment.start

      expect(environment.state).to eq('available')
    end

    context 'when environment has auto stop period' do
      let!(:environment) { create(:environment, :available, :auto_stoppable, project: project) }

      it 'clears auto stop period when the environment has stopped' do
        environment.stop!

        expect(environment.auto_stop_at).to be_nil
      end

      it 'does not clear auto stop period when the environment has not stopped' do
        expect(environment.auto_stop_at).to be_present
      end
    end
  end

  describe '.for_name_like' do
    subject { project.environments.for_name_like(query, limit: limit) }

    let!(:environment) { create(:environment, name: 'production', project: project) }
    let(:query) { 'pro' }
    let(:limit) { 5 }

    it 'returns a found name' do
      is_expected.to include(environment)
    end

    context 'when query is production' do
      let(:query) { 'production' }

      it 'returns a found name' do
        is_expected.to include(environment)
      end
    end

    context 'when query is productionA' do
      let(:query) { 'productionA' }

      it 'returns empty array' do
        is_expected.to be_empty
      end
    end

    context 'when query is empty' do
      let(:query) { '' }

      it 'returns a found name' do
        is_expected.to include(environment)
      end
    end

    context 'when query is nil' do
      let(:query) {}

      it 'raises an error' do
        expect { subject }.to raise_error(NoMethodError)
      end
    end

    context 'when query is partially matched in the middle of environment name' do
      let(:query) { 'duction' }

      it 'returns empty array' do
        is_expected.to be_empty
      end
    end

    context 'when query contains a wildcard character' do
      let(:query) { 'produc%' }

      it 'prevents wildcard injection' do
        is_expected.to be_empty
      end
    end
  end

  describe '.for_name_like_within_folder' do
    subject { project.environments.for_name_like_within_folder(query, limit: limit) }

    let!(:environment) { create(:environment, name: 'review/test-app', project: project) }
    let!(:environment_a) { create(:environment, name: 'test-app', project: project) }
    let(:query) { 'test' }
    let(:limit) { 5 }

    it 'returns a found name' do
      is_expected.to contain_exactly(environment)
    end

    it 'does not return environment without folder' do
      is_expected.not_to include(environment_a)
    end

    context 'when query string is the full environment name within a folder' do
      let(:query) { 'test-app' }

      it 'returns a found name' do
        is_expected.to include(environment)
      end
    end

    context 'when query string has characters not in the environment' do
      let(:query) { 'test-app-a' }

      it 'returns empty array' do
        is_expected.to be_empty
      end
    end

    context 'when the environment folder is the same as the starting characters of the environment name' do
      let!(:environment) { create(:environment, name: 'test/test-app', project: project) }

      it 'returns a found name' do
        is_expected.to contain_exactly(environment)
      end
    end

    context 'when the environment folder has characters in the starting characters of the environment name' do
      let!(:environment) { create(:environment, name: 'atr/test-app', project: project) }

      it 'returns a found name' do
        is_expected.to contain_exactly(environment)
      end
    end

    context 'when query is empty string' do
      let(:query) { '' }
      let!(:environment_b) { create(:environment, name: 'review/test-app-1', project: project) }

      it 'returns only the foldered environments' do
        is_expected.to contain_exactly(environment, environment_b)
      end
    end

    context 'when query is nil' do
      let(:query) {}

      it 'raises an error' do
        expect { subject }.to raise_error(NoMethodError)
      end
    end

    context 'when query is partially matched in the middle of environment name' do
      let(:query) { 'app' }

      it 'returns empty array' do
        is_expected.to be_empty
      end
    end

    context 'when query contains a wildcard character' do
      let(:query) { 'test%' }

      it 'prevents wildcard injection' do
        is_expected.to be_empty
      end
    end
  end

  describe '.auto_stoppable' do
    subject { described_class.auto_stoppable(limit) }

    let(:limit) { 100 }

    context 'when environment is auto-stoppable' do
      let!(:environment) { create(:environment, :auto_stoppable) }

      it { is_expected.to eq([environment]) }
    end

    context 'when environment is not auto-stoppable' do
      let!(:environment) { create(:environment) }

      it { is_expected.to be_empty }
    end
  end

  describe '.auto_deletable' do
    subject { described_class.auto_deletable(limit) }

    let(:limit) { 100 }

    context 'when environment is auto-deletable' do
      let!(:environment) { create(:environment, :auto_deletable) }

      it { is_expected.to eq([environment]) }
    end

    context 'when environment is not auto-deletable' do
      let!(:environment) { create(:environment) }

      it { is_expected.to be_empty }
    end
  end

  describe '.long_stopping' do
    subject { described_class.long_stopping }

    let_it_be(:project) { create(:project) }
    let(:environment) { create(:environment, project: project) }
    let(:long) { (described_class::LONG_STOP + 1.day).ago }
    let(:short) { (described_class::LONG_STOP - 1.day).ago }

    context 'when a stopping environment has not been updated recently' do
      before do
        environment.update!(state: :stopping, updated_at: long)
      end

      it { is_expected.to eq([environment]) }
    end

    context 'when a stopping environment has been updated recently' do
      before do
        environment.update!(state: :stopping, updated_at: short)
      end

      it { is_expected.to be_empty }
    end

    context 'when a non stopping environment has not been updated recently' do
      before do
        environment.update!(state: :available, updated_at: long)
      end

      it { is_expected.to be_empty }
    end

    context 'when a non stopping environment has been updated recently' do
      before do
        environment.update!(state: :available, updated_at: short)
      end

      it { is_expected.to be_empty }
    end
  end

  describe '.pluck_names' do
    subject { described_class.pluck_names }

    let!(:environment) { create(:environment, name: 'production', project: project) }

    it 'plucks names' do
      is_expected.to eq(%w[production])
    end
  end

  describe '.for_tier' do
    let_it_be(:environment) { create(:environment, :production) }

    it 'returns the production environment when searching for production tier' do
      expect(described_class.for_tier(:production)).to eq([environment])
    end

    it 'returns nothing when searching for staging tier' do
      expect(described_class.for_tier(:staging)).to be_empty
    end
  end

  describe '.for_type' do
    it 'filters by type' do
      create(:environment)
      create(:environment, name: 'type1/prod')
      env = create(:environment, name: 'type2/prod')

      expect(described_class.for_type('type2')).to contain_exactly(env)
    end
  end

  describe '#guess_tier' do
    using RSpec::Parameterized::TableSyntax

    subject { environment.send(:guess_tier) }

    let(:environment) { build(:environment, name: name) }

    where(:name, :tier) do
      'review/feature'     | described_class.tiers[:development]
      'review/product'     | described_class.tiers[:development]
      'DEV'                | described_class.tiers[:development]
      'development'        | described_class.tiers[:development]
      'trunk'              | described_class.tiers[:development]
      'dev'                | described_class.tiers[:development]
      'review/app'         | described_class.tiers[:development]
      'PRODUCTION'         | described_class.tiers[:production]
      'prod'               | described_class.tiers[:production]
      'prod-east-2'        | described_class.tiers[:production]
      'us-prod-east'       | described_class.tiers[:production]
      'fe-production'      | described_class.tiers[:production]
      'test'               | described_class.tiers[:testing]
      'TEST'               | described_class.tiers[:testing]
      'testing'            | described_class.tiers[:testing]
      'testing-prd'        | described_class.tiers[:testing]
      'acceptance-testing' | described_class.tiers[:testing]
      'production-test'    | described_class.tiers[:testing]
      'test-production'    | described_class.tiers[:testing]
      'QC'                 | described_class.tiers[:testing]
      'qa-env-2'           | described_class.tiers[:testing]
      'gstg'               | described_class.tiers[:staging]
      'staging'            | described_class.tiers[:staging]
      'stage'              | described_class.tiers[:staging]
      'Model'              | described_class.tiers[:staging]
      'MODL'               | described_class.tiers[:staging]
      'Pre-production'     | described_class.tiers[:staging]
      'pre'                | described_class.tiers[:staging]
      'Demo'               | described_class.tiers[:staging]
      'staging'            | described_class.tiers[:staging]
      'pre-prod'           | described_class.tiers[:staging]
      'blue-kit-stage'     | described_class.tiers[:staging]
      'nonprod'            | described_class.tiers[:staging]
      'nonlive'            | described_class.tiers[:staging]
      'non-prod'           | described_class.tiers[:staging]
      'non-live'           | described_class.tiers[:staging]
      'gprd'               | described_class.tiers[:production]
      'gprd-cny'           | described_class.tiers[:production]
      'production'         | described_class.tiers[:production]
      'Production'         | described_class.tiers[:production]
      'PRODUCTION'         | described_class.tiers[:production]
      'Production/eu'      | described_class.tiers[:production]
      'production/eu'      | described_class.tiers[:production]
      'PRODUCTION/EU'      | described_class.tiers[:production]
      'productioneu'       | described_class.tiers[:production]
      'store-produce'      | described_class.tiers[:production]
      'unproductive'       | described_class.tiers[:production]
      'production/www.gitlab.com' | described_class.tiers[:production]
      'prod'               | described_class.tiers[:production]
      'PROD'               | described_class.tiers[:production]
      'Live'               | described_class.tiers[:production]
      'canary'             | described_class.tiers[:other]
      'other'              | described_class.tiers[:other]
      'EXP'                | described_class.tiers[:other]
      'something-else'     | described_class.tiers[:other]
    end

    with_them do
      it { is_expected.to eq(tier) }
    end
  end

  describe '#expire_etag_cache' do
    let(:store) { Gitlab::EtagCaching::Store.new }

    it 'changes the cached value' do
      old_value = store.get(environment.etag_cache_key)

      environment.stop

      expect(store.get(environment.etag_cache_key)).not_to eq(old_value)
    end
  end

  describe '.with_deployment' do
    subject { described_class.with_deployment(sha, status: status) }

    let(:environment) { create(:environment, project: project) }
    let(:sha) { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }
    let(:status) { nil }

    context 'when deployment has the specified sha' do
      let!(:deployment) { create(:deployment, environment: environment, sha: sha) }

      it { is_expected.to eq([environment]) }

      context 'with success status filter' do
        let(:status) { :success }

        it { is_expected.to be_empty }
      end

      context 'with created status filter' do
        let(:status) { :created }

        it { is_expected.to contain_exactly(environment) }
      end
    end

    context 'when deployment does not have the specified sha' do
      let!(:deployment) { create(:deployment, environment: environment, sha: 'ddd0f15ae83993f5cb66a927a28673882e99100b') }

      it { is_expected.to be_empty }
    end
  end

  describe '#folder_name' do
    context 'when it is inside a folder' do
      subject(:environment) do
        create(:environment, name: 'staging/review-1', project: project)
      end

      it 'returns a top-level folder name' do
        expect(environment.folder_name).to eq 'staging'
      end
    end

    context 'when the environment if a top-level item itself' do
      subject(:environment) do
        create(:environment, name: 'production')
      end

      it 'returns an environment name' do
        expect(environment.folder_name).to eq 'production'
      end
    end
  end

  describe '#name_without_type' do
    context 'when it is inside a folder' do
      subject(:environment) do
        create(:environment, name: 'staging/review-1')
      end

      it 'returns name without folder' do
        expect(environment.name_without_type).to eq 'review-1'
      end
    end

    context 'when the environment if a top-level item itself' do
      subject(:environment) do
        create(:environment, name: 'production')
      end

      it 'returns full name' do
        expect(environment.name_without_type).to eq 'production'
      end
    end
  end

  describe '#includes_commit?' do
    let(:project) { create(:project, :repository) }

    context 'without a last deployment' do
      it "returns false" do
        expect(environment.includes_commit?('HEAD')).to be false
      end
    end

    context 'with a last deployment' do
      let!(:deployment) do
        create(:deployment, :success, environment: environment, sha: project.commit('master').id)
      end

      context 'in the same branch' do
        it 'returns true' do
          expect(environment.includes_commit?(RepoHelpers.sample_commit.id)).to be true
        end
      end

      context 'not in the same branch' do
        before do
          deployment.update!(sha: project.commit('feature').id)
        end

        it 'returns false' do
          expect(environment.includes_commit?(RepoHelpers.sample_commit.id)).to be false
        end
      end
    end
  end

  describe '#environment_type' do
    subject { environment.environment_type }

    it 'sets a environment type if name has multiple segments' do
      environment.update!(name: 'production/worker.gitlab.com')

      is_expected.to eq('production')
    end

    it 'nullifies a type if it\'s a simple name' do
      environment.update!(name: 'production')

      is_expected.to be_nil
    end
  end

  describe '#stop_actions_available?' do
    subject { environment.stop_actions_available? }

    context 'when no other actions' do
      it { is_expected.to be_falsey }
    end

    context 'when matching action is defined' do
      let(:build) { create(:ci_build, :success) }

      let!(:deployment) do
        create(
          :deployment,
          :success,
          environment: environment,
          deployable: build,
          on_stop: 'close_app'
        )
      end

      let!(:close_action) do
        create(:ci_build, :manual, pipeline: build.pipeline, name: 'close_app')
      end

      context 'when environment is available' do
        before do
          environment.start
        end

        it { is_expected.to be_truthy }
      end

      context 'when environment is stopped' do
        before do
          environment.stop
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#stop_with_actions!', :request_store do
    let(:user) { create(:user) }

    subject { environment.stop_with_actions! }

    shared_examples_for 'stop with playing a teardown job' do
      context 'when no other actions' do
        context 'environment is available' do
          before do
            environment.update!(state: :available)
          end

          it do
            actions = subject

            expect(environment).to be_stopped
            expect(actions).to be_empty
          end

          context 'when the auto stop setting is set to :with_action' do
            before do
              environment.update!(auto_stop_setting: :with_action)
            end

            it 'does not stop the environment' do
              actions = subject

              expect(environment).to be_available
              expect(actions).to be_empty
            end
          end
        end

        context 'environment is already stopped' do
          before do
            environment.update!(state: :stopped)
          end

          it do
            subject

            expect(environment).to be_stopped
          end
        end
      end

      context 'when matching action is defined' do
        let(:pipeline) { create(:ci_pipeline, project: project) }
        let(:job_a) { create(factory_type, :success, pipeline: pipeline, **factory_options) }

        before do
          create(:deployment, :success,
            environment: environment,
            deployable: job_a,
            on_stop: 'close_app_a')
        end

        context 'when user is not allowed to stop environment' do
          let!(:close_action) do
            create(factory_type, :manual, pipeline: pipeline, name: 'close_app_a', **factory_options)
          end

          it 'raises an exception' do
            expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
          end
        end

        context 'when user is allowed to stop environment' do
          before do
            project.add_developer(user)

            create(:protected_branch, :developers_can_merge, name: 'master', project: project)
          end

          context 'when action did not yet finish' do
            let!(:close_action) do
              create(factory_type, :manual, pipeline: pipeline, name: 'close_app_a', **factory_options)
            end

            it 'returns the same action' do
              action = subject.first
              expect(action).to eq(close_action)
              expect(action.user).to eq(user)
            end

            it 'environment is not stopped' do
              subject

              expect(environment).not_to be_stopped
            end
          end

          context 'if action did finish' do
            let!(:close_action) do
              create(factory_type, :manual, :success, pipeline: pipeline, name: 'close_app_a', **factory_options)
            end

            it 'returns a new action of the same type when build job' do
              skip unless factory_type == :ci_build

              action = subject.first

              expect(action).to be_persisted
              expect(action.name).to eq(close_action.name)
              expect(action.user).to eq(user)
            end

            it 'does nothing when bridge job' do
              skip unless factory_type == :ci_bridge

              action = subject.first

              expect(action).to be_nil
            end
          end

          context 'close action does not raise ActiveRecord::StaleObjectError' do
            let!(:close_action) do
              create(factory_type, :manual, pipeline: pipeline, name: 'close_app_a', **factory_options)
            end

            before do
              # preload the job
              environment.stop_actions

              # Update record as the other process. This makes `environment.stop_action` stale.
              close_action.drop!
            end

            it 'successfully plays the job even if the job was a stale object when build job' do
              skip unless factory_type == :ci_build

              # Since job is droped.
              expect(close_action.processed).to be_falsey

              # it encounters the StaleObjectError at first, but reloads the object and runs `job.play`
              expect { subject }.not_to raise_error

              # Now the job should be processed.
              expect(close_action.reload.processed).to be_truthy
            end

            it 'does nothing when bridge job' do
              skip unless factory_type == :ci_bridge

              expect(close_action.processed).to be_falsey

              # it encounters the StaleObjectError at first, but reloads the object and runs `job.play`
              expect { subject }.not_to raise_error

              # Bridge is not retried currently.
              expect(close_action.processed).to be_falsey
            end
          end
        end
      end

      context 'when there are more then one stop action for the environment' do
        let(:pipeline) { create(:ci_pipeline, project: project) }
        let(:job_a) { create(factory_type, :success, pipeline: pipeline, **factory_options) }
        let(:job_b) { create(factory_type, :success, pipeline: pipeline, **factory_options) }

        let!(:close_actions) do
          [
            create(factory_type, :manual, pipeline: pipeline, name: 'close_app_a', **factory_options),
            create(factory_type, :manual, pipeline: pipeline, name: 'close_app_b', **factory_options)
          ]
        end

        before do
          project.add_developer(user)

          create(:deployment, :success,
            environment: environment,
            deployable: job_a,
            finished_at: 5.minutes.ago,
            on_stop: 'close_app_a')

          create(:deployment, :success,
            environment: environment,
            deployable: job_b,
            finished_at: 1.second.ago,
            on_stop: 'close_app_b')
        end

        it 'returns the same actions' do
          actions = subject

          expect(actions.count).to eq(close_actions.count)
          expect(actions.pluck(:id)).to match_array(close_actions.pluck(:id))
          expect(actions.pluck(:user)).to match_array(close_actions.pluck(:user))
        end

        context 'when stop actions are associated to users requiring composite identity' do
          let(:user) { create(:user, :service_account, composite_identity_enforced: true) }
          let(:scoped_user) { create(:user) }
          let(:user_a) { user }
          let(:user_b) { user }

          before do
            project.add_maintainer(user_a)
            project.add_maintainer(user_b)
            project.add_maintainer(scoped_user)

            job = close_actions.first
            job.update!(user: user_a, options: job.options.merge(scoped_user_id: scoped_user.id))
            job = close_actions.last
            job.update!(user: user_b, options: job.options.merge(scoped_user_id: scoped_user.id))
          end

          it 'ensures composite identity is present when checking permissions to run the actions' do
            expect(::Gitlab::Auth::Identity).to receive(:link_from_job).twice.and_call_original

            actions = subject

            expect(actions.count).to eq(close_actions.count)
            expect(actions.pluck(:id)).to match_array(close_actions.pluck(:id))
            expect(actions.pluck(:user)).to match_array(close_actions.pluck(:user))
          end

          context 'when request has composite identity is already linked under different users' do
            let(:another_scoped_user) { create(:user) }

            before do
              ::Gitlab::Auth::Identity.new(user).link!(another_scoped_user)
            end

            it 'denies access' do
              expect { subject }.to raise_error(::Gitlab::Access::AccessDeniedError)
            end
          end

          context 'when stop actions have different users' do
            context 'when stop actions have different human users' do
              let(:user_a) { create(:user) }
              let(:user_b) { create(:user) }

              it 'process the jobs' do
                expect(subject.count).to eq(close_actions.count)
              end
            end

            context 'when stop actions have composite identity user and human user' do
              let(:user_b) { create(:user) }

              it 'process the jobs' do
                expect(subject.count).to eq(close_actions.count)
              end
            end

            context 'when stop actions have different composite identity users' do
              let(:user_b) { create(:user, :service_account, composite_identity_enforced: true) }

              it 'raises an error' do
                expect { subject }.to raise_error(Gitlab::Auth::Identity::TooManyIdentitiesLinkedError)
              end
            end
          end
        end

        context 'when there are failed builds' do
          before do
            create(factory_type, :failed, pipeline: pipeline, name: 'close_app_c', **factory_options)

            create(:deployment, :failed,
              environment: environment,
              deployable: create(factory_type, pipeline: pipeline, **factory_options),
              on_stop: 'close_app_c')
          end

          it 'returns only stop actions from successful builds' do
            actions = subject

            expect(actions).to match_array(close_actions)
            expect(actions.count).to eq(pipeline.latest_successful_jobs.count)
          end
        end
      end
    end

    it_behaves_like 'stop with playing a teardown job' do
      let(:factory_type) { :ci_build }
      let(:factory_options) { { user: user } }
    end

    it_behaves_like 'stop with playing a teardown job' do
      let(:factory_type) { :ci_bridge }
      let(:factory_options) { { user: user, downstream: project } }
    end
  end

  describe '#stop_actions' do
    subject do
      # Environment#stop_actions is strong-memoized,
      # so we need to reload the `environment` to make sure
      # that the updated `stop_actions` records are being fetched
      reloaded_environment = described_class.find(environment.id)
      reloaded_environment.stop_actions
    end

    context 'when there are no deployments and builds' do
      it { is_expected.to match_array([]) }
    end

    context 'when there are multiple deployments with actions' do
      def create_deployment_with_stop_action(status, pipeline, stop_action_name)
        build = create(:ci_build, status, project: project, pipeline: pipeline)
        stop_action = create(:ci_build, :manual, project: project, pipeline: pipeline, name: stop_action_name)
        create(:deployment, status, project: project, environment: environment, deployable: build, on_stop: stop_action_name)

        stop_action
      end

      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:environment) { create(:environment, project: project) }

      let_it_be(:successful_pipeline) { create(:ci_pipeline, project: project) }
      let_it_be(:successful_pipeline_stop) { create_deployment_with_stop_action(:success, successful_pipeline, 'successful_pipeline_stop') }

      let_it_be(:finished_pipeline) { create(:ci_pipeline, :failed, project: project) }
      let_it_be(:finished_pipeline_stop_a) { create_deployment_with_stop_action(:failed, finished_pipeline, 'finished_pipeline_stop_a') }
      let_it_be(:finished_pipeline_stop_b) { create_deployment_with_stop_action(:canceled, finished_pipeline, 'finished_pipeline_stop_b') }

      before_all do
        # create the running pipeline and associated records
        # this is created to show that stop jobs of the latest pipeline are not picked up if the pipeline is still running
        running_pipeline = create(:ci_pipeline, :running, project: project)
        create(:ci_build, :manual, project: project, pipeline: running_pipeline, name: 'running_pipeline_stop')
        create_deployment_with_stop_action(:created, running_pipeline, 'running_pipeline_stop')
      end

      it 'returns the stop actions of the finished deployments in the last finished pipeline' do
        expect(subject).to contain_exactly(
          finished_pipeline_stop_a,
          finished_pipeline_stop_b
        )
      end

      context 'when the last finished pipeline has a successful deployment' do
        let_it_be(:finished_pipeline_stop_c) { create_deployment_with_stop_action(:success, finished_pipeline, 'finished_pipeline_stop_c') }

        it 'returns the stop actions of the finished deployments in the last finished pipeline' do
          expect(subject).to contain_exactly(
            finished_pipeline_stop_a,
            finished_pipeline_stop_b,
            finished_pipeline_stop_c
          )
        end
      end
    end
  end

  describe '#last_finished_deployment_group' do
    it 'delegates to Deployment' do
      expect(Deployment).to receive(:last_finished_deployment_group_for_environment).with(environment)

      environment.last_finished_deployment_group
    end
  end

  describe 'recently_updated_on_branch?' do
    subject { environment.recently_updated_on_branch?('feature') }

    context 'when last deployment to environment is the most recent one' do
      before do
        create(:deployment, :success, environment: environment, ref: 'feature')
      end

      it { is_expected.to be true }
    end

    context 'when last deployment to environment is not the most recent' do
      before do
        create(:deployment, :success, environment: environment, ref: 'feature')
        create(:deployment, :success, environment: environment, ref: 'master')
      end

      it { is_expected.to be false }
    end
  end

  describe '#reset_auto_stop' do
    subject { environment.reset_auto_stop }

    let(:environment) { create(:environment, :auto_stoppable) }

    it 'nullifies the auto_stop_at' do
      expect { subject }.to change(environment, :auto_stop_at).from(Time).to(nil)
    end
  end

  describe '#actions_for' do
    let(:deployment) { create(:deployment, :success, environment: environment) }
    let(:pipeline) { deployment.deployable.pipeline }
    let!(:review_action) { create(:ci_build, :manual, name: 'review-apps', pipeline: pipeline, environment: 'review/$CI_COMMIT_REF_NAME') }
    let!(:production_action) { create(:ci_build, :manual, name: 'production', pipeline: pipeline, environment: 'production') }

    it 'returns a list of actions with matching environment' do
      expect(environment.actions_for('review/master')).to contain_exactly(review_action)
    end
  end

  describe '.deployments' do
    subject { environment.deployments }

    context 'when there is a deployment record with created status' do
      let(:deployment) { create(:deployment, :created, environment: environment) }

      it 'does not return the record' do
        is_expected.to be_empty
      end
    end

    context 'when there is a deployment record with running status' do
      let(:deployment) { create(:deployment, :running, environment: environment) }

      it 'does not return the record' do
        is_expected.to be_empty
      end
    end

    context 'when there is a deployment record with success status' do
      let(:deployment) { create(:deployment, :success, environment: environment) }

      it 'returns the record' do
        is_expected.to eq([deployment])
      end
    end
  end

  describe '.last_deployment' do
    subject { environment.last_deployment }

    before do
      allow_next_instance_of(Deployment) do |instance|
        allow(instance).to receive(:create_ref)
      end
    end

    context 'when there is an old deployment record' do
      let!(:previous_deployment) { create(:deployment, :success, environment: environment) }

      context 'when there is a deployment record with created status' do
        let!(:deployment) { create(:deployment, environment: environment) }

        it 'returns the previous deployment' do
          is_expected.to eq(previous_deployment)
        end
      end

      context 'when there is a deployment record with running status' do
        let!(:deployment) { create(:deployment, :running, environment: environment) }

        it 'returns the previous deployment' do
          is_expected.to eq(previous_deployment)
        end
      end

      context 'when there is a deployment record with failed status' do
        let!(:deployment) { create(:deployment, :failed, environment: environment) }

        it 'returns the previous deployment' do
          is_expected.to eq(previous_deployment)
        end
      end

      context 'when there is a deployment record with success status' do
        let!(:deployment) { create(:deployment, :success, environment: environment) }
        let!(:old_deployment) { create(:deployment, :success, environment: environment, finished_at: 2.days.ago) }

        it 'returns the latest successful deployment' do
          is_expected.to eq(deployment)
        end

        it 'returns the deployment with the latest finished_at' do
          expect(old_deployment.finished_at < deployment.finished_at).to be_truthy

          is_expected.to eq(deployment)
        end
      end
    end
  end

  describe 'Last deployment relations' do
    Deployment::FINISHED_STATUSES.each do |status|
      it "returns the last #{status} deployment" do
        create(:deployment, status.to_sym, environment: environment, finished_at: 1.day.ago)
        expected = create(:deployment, status.to_sym, environment: environment, finished_at: Time.current)

        expect(environment.public_send(:"last_#{status}_deployment")).to eq(expected)
      end
    end

    Deployment::UPCOMING_STATUSES.each do |status|
      it "returns the last #{status} deployment" do
        create(:deployment, status.to_sym, environment: environment)
        expected = create(:deployment, status.to_sym, environment: environment)

        expect(environment.public_send(:"last_#{status}_deployment")).to eq(expected)
      end
    end
  end

  describe '#last_deployable' do
    subject { environment.last_deployable }

    context 'does not join across databases' do
      let(:pipeline_a) { create(:ci_pipeline, project: project) }
      let(:pipeline_b) { create(:ci_pipeline, project: project) }
      let(:ci_build_a) { create(:ci_build, project: project, pipeline: pipeline_a) }
      let(:ci_build_b) { create(:ci_build, project: project, pipeline: pipeline_b) }

      before do
        create(:deployment, :success, project: project, environment: environment, deployable: ci_build_a)
        create(:deployment, :failed, project: project, environment: environment, deployable: ci_build_b)
      end

      it 'when called' do
        with_cross_joins_prevented do
          expect(subject.id).to eq(ci_build_a.id)
        end
      end
    end
  end

  describe '#last_visible_deployment' do
    subject { environment.last_visible_deployment }

    before do
      allow_any_instance_of(Deployment).to receive(:create_ref)
    end

    context 'when there is an old deployment record' do
      let!(:previous_deployment) { create(:deployment, :success, environment: environment) }

      context 'when there is a deployment record with created status' do
        let!(:deployment) { create(:deployment, environment: environment) }

        it { is_expected.to eq(previous_deployment) }
      end

      context 'when there is a deployment record with running status' do
        let!(:deployment) { create(:deployment, :running, environment: environment) }

        it { is_expected.to eq(deployment) }
      end

      context 'when there is a deployment record with success status' do
        let!(:deployment) { create(:deployment, :success, environment: environment) }

        it { is_expected.to eq(deployment) }
      end

      context 'when there is a deployment record with failed status' do
        let!(:deployment) { create(:deployment, :failed, environment: environment) }

        it { is_expected.to eq(deployment) }
      end

      context 'when there is a deployment record with canceled status' do
        let!(:deployment) { create(:deployment, :canceled, environment: environment) }

        it { is_expected.to eq(deployment) }
      end
    end
  end

  describe '#last_visible_deployable' do
    subject { environment.last_visible_deployable }

    let!(:deployment) do
      create(:deployment, :success, project: project, environment: environment, deployable: deployable)
    end

    let!(:deployable) { create(:ci_build, :success, project: project) }

    it 'fetches the deployable through the last visible deployment' do
      is_expected.to eq(deployable)
    end
  end

  describe '#last_visible_pipeline' do
    subject { environment.last_visible_pipeline }

    let!(:deployment) do
      create(:deployment, :success, project: project, environment: environment, deployable: deployable)
    end

    let!(:deployable) { create(:ci_build, :success, project: project, pipeline: pipeline) }
    let!(:pipeline) { create(:ci_pipeline, :success, project: project) }

    it 'fetches the pipeline through the last visible deployment' do
      is_expected.to eq(pipeline)
    end
  end

  describe '#last_finished_deployment' do
    using RSpec::Parameterized::TableSyntax

    subject { environment.last_finished_deployment }

    before do
      allow_any_instance_of(Deployment).to receive(:create_ref)
    end

    where(:finished_status) { [:success, :failed, :canceled] }

    with_them do
      let!(:finished_deployment) do
        create(:deployment, finished_status, environment: environment)
      end

      context 'when latest deployment is not finished' do
        let!(:latest_deployment) { create(:deployment, :running, environment: environment) }

        it 'returns the previous finished deployment' do
          is_expected.to eq(finished_deployment)
        end
      end

      context 'when latest deployment is finished' do
        it 'returns the finished deployment' do
          is_expected.to eq(finished_deployment)
        end
      end
    end
  end

  describe '#last_finished_deployable' do
    subject { environment.last_finished_deployable }

    let!(:deployment) do
      create(:deployment, :canceled, project: project, environment: environment, deployable: deployable)
    end

    let!(:deployable) { create(:ci_build, :canceled, project: project) }

    it 'fetches the deployable through the last finished deployment' do
      is_expected.to eq(deployable)
    end
  end

  describe '#last_finished_pipeline' do
    subject { environment.last_finished_pipeline }

    let!(:deployment) do
      create(:deployment, :canceled, project: project, environment: environment, deployable: deployable)
    end

    let!(:deployable) { create(:ci_build, :canceled, project: project, pipeline: pipeline) }
    let!(:pipeline) { create(:ci_pipeline, :canceled, project: project) }

    it 'fetches the pipeline through the last finished deployment' do
      is_expected.to eq(pipeline)
    end
  end

  describe '#latest_finished_jobs' do
    subject { environment.latest_finished_jobs }

    let(:pipeline_a) { create(:ci_pipeline, project: project) }
    let(:pipeline_b) { create(:ci_pipeline, project: project) }
    let(:ci_build_a_1) { create(:ci_build, :success, project: project, pipeline: pipeline_a) }
    let(:ci_build_a_2) { create(:ci_build, :failed, project: project, pipeline: pipeline_a) }
    let(:ci_build_a_3) { create(:ci_build, :canceled, project: project, pipeline: pipeline_a) }
    let(:ci_build_a_4) { create(:ci_build, :running, project: project, pipeline: pipeline_a) }
    let(:ci_build_b_1) { create(:ci_build, :running, project: project, pipeline: pipeline_b) }

    before do
      create(:deployment, :success, project: project, environment: environment, deployable: ci_build_a_1)
      create(:deployment, :failed, project: project, environment: environment, deployable: ci_build_a_2)
      create(:deployment, :canceled, project: project, environment: environment, deployable: ci_build_a_3)
      create(:deployment, :running, project: project, environment: environment, deployable: ci_build_a_4)
      create(:deployment, :running, project: project, environment: environment, deployable: ci_build_b_1)
    end

    it 'fetches the latest finished jobs through the last pipeline with a finished deployment' do
      is_expected.to contain_exactly(ci_build_a_1, ci_build_a_2, ci_build_a_3)
    end
  end

  describe '#upcoming_deployment' do
    subject { environment.upcoming_deployment }

    context 'when environment has a successful deployment' do
      let!(:deployment) { create(:deployment, :success, environment: environment, project: project) }

      it { is_expected.to be_nil }
    end

    context 'when environment has a running deployment' do
      let!(:deployment) { create(:deployment, :running, environment: environment, project: project) }

      it { is_expected.to eq(deployment) }
    end

    context 'when environment has a blocked deployment' do
      let!(:deployment) { create(:deployment, :blocked, environment: environment, project: project) }

      it { is_expected.to eq(deployment) }
    end
  end

  describe '#has_terminals?' do
    subject { environment.has_terminals? }

    context 'when the environment is available' do
      context 'with a deployment service' do
        context 'when user configured kubernetes from CI/CD > Clusters' do
          let!(:cluster) { create(:cluster, :project, :provided_by_gcp, projects: [project]) }

          context 'with deployment' do
            let!(:deployment) { create(:deployment, :success, environment: environment) }

            it { is_expected.to be_truthy }
          end

          context 'without deployments' do
            it { is_expected.to be_falsy }
          end
        end
      end

      context 'without a deployment service' do
        it { is_expected.to be_falsy }
      end
    end

    context 'when the environment is unavailable' do
      before do
        environment.stop
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '#deployment_platform' do
    context 'when there is a deployment platform for environment' do
      let!(:cluster) do
        create(:cluster, :provided_by_gcp, environment_scope: '*', projects: [project])
      end

      it 'finds a deployment platform' do
        expect(environment.deployment_platform).to eq cluster.platform
      end
    end

    context 'when there is no deployment platform for environment' do
      it 'returns nil' do
        expect(environment.deployment_platform).to be_nil
      end
    end

    it 'checks deployment platforms associated with a project' do
      expect(project).to receive(:deployment_platform)
        .with(environment: environment.name)

      environment.deployment_platform
    end
  end

  describe '#deployment_namespace' do
    let(:environment) { create(:environment) }

    subject { environment.deployment_namespace }

    before do
      allow(environment).to receive(:deployment_platform).and_return(deployment_platform)
    end

    context 'no deployment platform available' do
      let(:deployment_platform) { nil }

      it { is_expected.to be_nil }
    end

    context 'deployment platform is available' do
      let(:cluster) { create(:cluster, :provided_by_user, :project, projects: [environment.project]) }
      let(:deployment_platform) { cluster.platform }

      it 'retrieves a namespace from the cluster' do
        expect(cluster).to receive(:kubernetes_namespace_for)
          .with(environment).and_return('mock-namespace')

        expect(subject).to eq 'mock-namespace'
      end
    end
  end

  describe '#terminals' do
    subject { environment.terminals }

    before do
      allow(environment).to receive(:deployment_platform).and_return(double)
    end

    context 'reactive cache configuration' do
      it 'does not continue to spawn jobs' do
        expect(described_class.reactive_cache_lifetime).to be < described_class.reactive_cache_refresh_interval
      end
    end

    context 'reactive cache is empty' do
      before do
        stub_reactive_cache(environment, nil)
      end

      it { is_expected.to be_nil }
    end

    context 'reactive cache has pod data' do
      let(:cache_data) { Hash(pods: %w[pod1 pod2]) }

      before do
        stub_reactive_cache(environment, cache_data)
      end

      it 'retrieves terminals from the deployment platform' do
        expect(environment.deployment_platform)
          .to receive(:terminals).with(environment, cache_data)
          .and_return(:fake_terminals)

        is_expected.to eq(:fake_terminals)
      end
    end
  end

  describe '#calculate_reactive_cache' do
    let!(:cluster) { create(:cluster, :project, :provided_by_user, projects: [project]) }
    let!(:environment) { create(:environment, project: project) }
    let!(:deployment) { create(:deployment, :success, environment: environment, project: project) }

    subject { environment.calculate_reactive_cache }

    it 'overrides default reactive_cache_hard_limit to 10 Mb' do
      expect(described_class.reactive_cache_hard_limit).to eq(10.megabyte)
    end

    it 'returns cache data from the deployment platform' do
      expect(environment.deployment_platform).to receive(:calculate_reactive_cache_for)
        .with(environment).and_return(pods: %w[pod1 pod2])

      is_expected.to eq(pods: %w[pod1 pod2])
    end

    context 'environment does not have terminals available' do
      before do
        allow(environment).to receive(:has_terminals?).and_return(false)
      end

      it { is_expected.to be_nil }
    end

    context 'project is pending deletion' do
      before do
        allow(environment.project).to receive(:pending_delete?).and_return(true)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#has_metrics?' do
    subject { environment.has_metrics? }

    context 'when the environment is available' do
      context 'with a deployment service' do
        let_it_be(:project) { create(:project, :with_prometheus_integration, :repository) }

        context 'and a deployment' do
          let!(:deployment) { create(:deployment, environment: environment) }

          it { is_expected.to be_truthy }
        end

        context 'and no deployments' do
          it { is_expected.to be_truthy }
        end

        context 'and the prometheus adapter is not configured' do
          before do
            allow(environment.prometheus_adapter).to receive(:configured?).and_return(false)
          end

          it { is_expected.to be_falsy }
        end
      end

      context 'without a monitoring service' do
        it { is_expected.to be_falsy }
      end

      context 'when sample metrics are enabled' do
        before do
          stub_env('USE_SAMPLE_METRICS', 'true')
        end

        context 'with no prometheus adapter configured' do
          before do
            allow(environment.prometheus_adapter).to receive(:configured?).and_return(false)
          end

          it { is_expected.to be_truthy }
        end
      end
    end

    describe '#has_sample_metrics?' do
      subject { environment.has_metrics? }

      let(:project) { create(:project) }

      context 'when sample metrics are enabled' do
        before do
          stub_env('USE_SAMPLE_METRICS', 'true')
        end

        context 'with no prometheus adapter configured' do
          before do
            allow(environment.prometheus_adapter).to receive(:configured?).and_return(false)
          end

          it { is_expected.to be_truthy }
        end

        context 'with the environment stopped' do
          before do
            environment.stop
          end

          it { is_expected.to be_falsy }
        end
      end

      context 'when sample metrics are not enabled' do
        it { is_expected.to be_falsy }
      end
    end

    context 'when the environment is unavailable' do
      let_it_be(:project) { create(:project, :with_prometheus_integration) }

      before do
        environment.stop
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '#has_running_deployments?' do
    subject { environment.has_running_deployments? }

    it 'return false when no deployments exist' do
      is_expected.to eq(false)
    end

    context 'when deployment is running on the environment' do
      let!(:deployment) { create(:deployment, :running, environment: environment) }

      it 'return true' do
        is_expected.to eq(true)
      end
    end
  end

  describe '#additional_metrics' do
    let_it_be(:project) { create(:project, :with_prometheus_integration) }
    let(:metric_params) { [] }

    subject { environment.additional_metrics(*metric_params) }

    context 'when the environment has additional metrics' do
      before do
        allow(environment).to receive(:has_metrics?).and_return(true)
      end

      it 'returns the additional metrics from the deployment service' do
        expect(environment.prometheus_adapter)
          .to receive(:query)
          .with(:additional_metrics_environment, environment)
          .and_return(:fake_metrics)

        is_expected.to eq(:fake_metrics)
      end

      context 'when time window arguments are provided' do
        let(:metric_params) { [1552642245.067, Time.current] }

        it 'queries with the expected parameters' do
          expect(environment.prometheus_adapter)
            .to receive(:query)
            .with(:additional_metrics_environment, environment, *metric_params.map(&:to_f))
            .and_return(:fake_metrics)

          is_expected.to eq(:fake_metrics)
        end
      end
    end

    context 'when the environment does not have metrics' do
      before do
        allow(environment).to receive(:has_metrics?).and_return(false)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#slug' do
    it "is automatically generated" do
      expect(environment.slug).not_to be_nil
    end

    it "is not regenerated if name changes" do
      original_slug = environment.slug
      environment.update!(name: environment.name.reverse)

      expect(environment.slug).to eq(original_slug)
    end

    it "regenerates the slug if nil" do
      environment = build(:environment, slug: nil)

      new_slug = environment.slug

      expect(new_slug).not_to be_nil
      expect(environment.slug).to eq(new_slug)
    end
  end

  describe '#ref_path' do
    subject(:environment) do
      create(:environment, name: 'staging / review-1')
    end

    it 'returns a path that uses the slug and does not have spaces' do
      expect(environment.ref_path).to start_with('refs/environments/staging-review-1-')
    end

    it "doesn't change when the slug is nil initially" do
      environment.slug = nil

      expect(environment.ref_path).to eq(environment.ref_path)
    end
  end

  describe '#external_url_for' do
    let(:source_path) { 'source/file.html' }
    let(:sha) { RepoHelpers.sample_commit.id }

    context 'when the public path is not known' do
      before do
        environment.external_url = 'http://example.com'
        allow(project).to receive(:public_path_for_source_path).with(source_path, sha).and_return(nil)
      end

      it 'returns nil' do
        expect(environment.external_url_for(source_path, sha)).to be_nil
      end
    end

    context 'when the public path is known' do
      where(:external_url, :public_path, :full_url) do
        'http://example.com'          | 'file.html'         | 'http://example.com/file.html'
        'http://example.com/'         | 'file.html'         | 'http://example.com/file.html'
        'http://example.com'          | '/file.html'        | 'http://example.com/file.html'
        'http://example.com/'         | '/file.html'        | 'http://example.com/file.html'
        'http://example.com/subpath'  | 'public/file.html'  | 'http://example.com/subpath/public/file.html'
        'http://example.com/subpath/' | 'public/file.html'  | 'http://example.com/subpath/public/file.html'
        'http://example.com/subpath'  | '/public/file.html' | 'http://example.com/subpath/public/file.html'
        'http://example.com/subpath/' | '/public/file.html' | 'http://example.com/subpath/public/file.html'
      end
      with_them do
        it 'returns the full external URL' do
          environment.external_url = external_url
          allow(project).to receive(:public_path_for_source_path).with(source_path, sha).and_return(public_path)

          expect(environment.external_url_for(source_path, sha)).to eq(full_url)
        end
      end
    end
  end

  describe '#prometheus_adapter' do
    it 'calls prometheus adapter service' do
      expect_next_instance_of(Gitlab::Prometheus::Adapter) do |instance|
        expect(instance).to receive(:prometheus_adapter)
      end

      subject.prometheus_adapter
    end
  end

  describe '#knative_services_finder' do
    let(:environment) { create(:environment) }

    subject { environment.knative_services_finder }

    context 'environment has no deployments' do
      it { is_expected.to be_nil }
    end

    context 'environment has a deployment' do
      context 'with no cluster associated' do
        let!(:deployment) { create(:deployment, :success, environment: environment) }

        it { is_expected.to be_nil }
      end

      context 'with a cluster associated' do
        let!(:deployment) { create(:deployment, :success, :on_cluster, environment: environment) }

        it 'calls the service finder' do
          expect(Clusters::KnativeServicesFinder).to receive(:new)
            .with(deployment.cluster, environment).and_return(:finder)

          is_expected.to eq :finder
        end
      end
    end
  end

  describe '#auto_stop_in' do
    subject { environment.auto_stop_in }

    context 'when environment will be expired' do
      let(:environment) { build(:environment, :will_auto_stop) }

      it 'returns when it will expire' do
        freeze_time { is_expected.to eq(1.day.to_i) }
      end
    end

    context 'when environment is not expired' do
      let(:environment) { build(:environment) }

      it { is_expected.to be_nil }
    end
  end

  describe '#auto_stop_in=' do
    subject { environment.auto_stop_in = value }

    let(:environment) { build(:environment) }

    where(:value, :expected_result) do
      '2 days'   | 2.days.to_i
      '1 week'   | 1.week.to_i
      '2h20min'  | (2.hours.to_i + 20.minutes.to_i)
      'abcdef'   | ChronicDuration::DurationParseError
      ''         | nil
      nil        | nil
      'never'    | nil
    end

    with_them do
      shared_examples 'for given values expected result is set' do
        it do
          freeze_time do
            if expected_result.is_a?(Integer) || expected_result.nil?
              subject

              expect(environment.auto_stop_in).to eq(expected_result)
            else
              expect { subject }.to raise_error(expected_result)
            end
          end
        end
      end

      context 'new assignment sets correct auto_stop_in' do
        include_examples 'for given values expected result is set'
      end

      context 'resets older value' do
        let(:environment) { create(:environment, auto_stop_at: 1.day.since.round) }

        include_examples 'for given values expected result is set'
      end
    end
  end

  describe '.for_id_and_slug' do
    subject { described_class.for_id_and_slug(environment.id, environment.slug) }

    let(:environment) { create(:environment) }

    it { is_expected.not_to be_nil }
  end

  describe '.find_or_create_by_name' do
    it 'finds an existing environment if it exists' do
      env = create(:environment)

      expect(described_class.find_or_create_by_name(env.name)).to eq(env)
    end

    it 'creates an environment if it does not exist' do
      env = project.environments.find_or_create_by_name('kittens')

      expect(env).to be_an_instance_of(described_class)
      expect(env).to be_persisted
    end
  end

  describe '#destroy' do
    it 'remove the deployment refs from gitaly' do
      deployment = create(:deployment, :success, environment: environment, project: project)
      deployment.create_ref

      expect { environment.destroy! }.to change { project.commit(deployment.ref_path) }.to(nil)
    end
  end

  describe '.count_by_state' do
    context 'when environments are not empty' do
      let!(:environment1) { create(:environment, project: project, state: 'stopped') }
      let!(:environment2) { create(:environment, project: project, state: 'available') }
      let!(:environment3) { create(:environment, project: project, state: 'stopped') }

      it 'returns the environments count grouped by state' do
        expect(project.environments.count_by_state).to eq({ stopped: 2, available: 1, stopping: 0 })
      end

      it 'returns the environments count grouped by state with zero value' do
        environment2.update!(state: 'stopped')
        expect(project.environments.count_by_state).to eq({ stopped: 3, available: 0, stopping: 0 })
      end
    end

    it 'returns zero state counts when environments are empty' do
      expect(project.environments.count_by_state).to eq({ stopped: 0, available: 0, stopping: 0 })
    end
  end

  describe '#has_opened_alert?' do
    subject { environment.has_opened_alert? }

    let_it_be(:project) { create(:project) }
    let_it_be(:environment, reload: true) { create(:environment, project: project) }

    context 'when environment has an triggered alert' do
      let!(:alert) { create(:alert_management_alert, :triggered, project: project, environment: environment) }

      it { is_expected.to be(true) }
    end

    context 'when environment has an resolved alert' do
      let!(:alert) { create(:alert_management_alert, :resolved, project: project, environment: environment) }

      it { is_expected.to be(false) }
    end

    context 'when environment does not have an alert' do
      it { is_expected.to be(false) }
    end
  end

  describe '#cancel_deployment_jobs!' do
    subject { environment.cancel_deployment_jobs! }

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:environment, reload: true) { create(:environment, project: project) }

    let!(:deployment) { create(:deployment, project: project, environment: environment, deployable: job) }
    let!(:job) { create(:ci_build, :running, project: project, environment: environment) }

    it 'cancels an active deployment job' do
      subject

      expect(job.reset).to be_canceled
    end

    context 'when deployment job is bridge' do
      let!(:job) { create(:ci_bridge, :running, project: project, environment: environment) }

      it 'does not cancel an active deployment job' do
        subject

        expect(job.reset).to be_running
      end
    end

    context 'when deployable does not exist' do
      before do
        deployment.update_column(:deployable_id, non_existing_record_id)
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error

        expect(job.reset).to be_running
      end
    end
  end

  describe '#rollout_status' do
    let!(:cluster) { create(:cluster, :project, :provided_by_user, projects: [project]) }
    let!(:environment) { create(:environment, project: project) }
    let!(:deployment) { create(:deployment, :success, environment: environment, project: project) }

    subject { environment.rollout_status }

    context 'environment does not have a deployment board available' do
      before do
        allow(environment).to receive(:has_terminals?).and_return(false)
      end

      it { is_expected.to be_nil }
    end

    context 'cached rollout status is present' do
      let(:pods) { %w[pod1 pod2] }
      let(:deployments) { %w[deployment1 deployment2] }

      before do
        stub_reactive_cache(environment, pods: pods, deployments: deployments)
      end

      it 'fetches the rollout status from the deployment platform' do
        expect(environment.deployment_platform).to receive(:rollout_status)
          .with(environment, { pods: pods, deployments: deployments })
          .and_return(:mock_rollout_status)

        is_expected.to eq(:mock_rollout_status)
      end
    end

    context 'cached rollout status is not present yet' do
      before do
        stub_reactive_cache(environment, nil)
      end

      it 'falls back to a loading status' do
        expect(::Gitlab::Kubernetes::RolloutStatus).to receive(:loading).and_return(:mock_loading_status)

        is_expected.to eq(:mock_loading_status)
      end
    end
  end

  describe '#ingresses' do
    subject { environment.ingresses }

    let(:deployment_platform) { double(:deployment_platform) }
    let(:deployment_namespace) { 'production' }

    before do
      allow(environment).to receive(:deployment_platform) { deployment_platform }
      allow(environment).to receive(:deployment_namespace) { deployment_namespace }
    end

    context 'when rollout status is available' do
      before do
        allow(environment).to receive(:rollout_status_available?) { true }
      end

      it 'fetches ingresses from the deployment platform' do
        expect(deployment_platform).to receive(:ingresses).with(deployment_namespace)

        subject
      end
    end

    context 'when rollout status is not available' do
      before do
        allow(environment).to receive(:rollout_status_available?) { false }
      end

      it 'does nothing' do
        expect(deployment_platform).not_to receive(:ingresses)

        subject
      end
    end
  end

  describe '#patch_ingress' do
    subject { environment.patch_ingress(ingress, data) }

    let(:ingress) { double(:ingress) }
    let(:data) { double(:data) }
    let(:deployment_platform) { double(:deployment_platform) }
    let(:deployment_namespace) { 'production' }

    before do
      allow(environment).to receive(:deployment_platform) { deployment_platform }
      allow(environment).to receive(:deployment_namespace) { deployment_namespace }
    end

    context 'when rollout status is available' do
      before do
        allow(environment).to receive(:rollout_status_available?) { true }
      end

      it 'fetches ingresses from the deployment platform' do
        expect(deployment_platform).to receive(:patch_ingress).with(deployment_namespace, ingress, data)

        subject
      end
    end

    context 'when rollout status is not available' do
      before do
        allow(environment).to receive(:rollout_status_available?) { false }
      end

      it 'does nothing' do
        expect(deployment_platform).not_to receive(:patch_ingress)

        subject
      end
    end
  end

  describe '#clear_all_caches' do
    subject { environment.clear_all_caches }

    it 'clears all caches on the environment' do
      expect_next_instance_of(Gitlab::EtagCaching::Store) do |store|
        expect(store).to receive(:touch).with(environment.etag_cache_key)
      end

      expect(environment).to receive(:clear_reactive_cache!)

      subject
    end
  end

  describe '#should_link_to_merge_requests?' do
    subject { environment.should_link_to_merge_requests? }

    context 'when environment is foldered' do
      context 'when environment is production tier' do
        let(:environment) { create(:environment, project: project, name: 'production/aws') }

        it { is_expected.to eq(true) }
      end

      context 'when environment is development tier' do
        let(:environment) { create(:environment, project: project, name: 'review/feature') }

        it { is_expected.to eq(false) }
      end
    end

    context 'when environment is unfoldered' do
      context 'when environment is production tier' do
        let(:environment) { create(:environment, project: project, name: 'production') }

        it { is_expected.to eq(true) }
      end

      context 'when environment is development tier' do
        let(:environment) { create(:environment, project: project, name: 'development') }

        it { is_expected.to eq(true) }
      end
    end
  end

  describe '#deploy_freezes' do
    let(:environment) { create(:environment, project: project, name: 'staging') }
    let(:freeze_period) { create(:ci_freeze_period, project: project) }

    subject { environment.deploy_freezes }

    it 'returns the freeze periods of the associated project' do
      expect(subject).to contain_exactly(freeze_period)
    end

    it 'caches the freeze periods' do
      allow(Gitlab::SafeRequestStore).to receive(:fetch).and_call_original

      expect(Gitlab::SafeRequestStore).to receive(:fetch).with("project:#{project.id}:freeze_periods_for_environments")
        .at_least(:once)
        .and_return([freeze_period])

      subject
    end
  end

  describe '#deployed_and_updated_before' do
    subject do
      described_class.deployed_and_updated_before(project_id, before)
    end

    let(:project_id) { project.id }
    let(:before) { 1.week.ago.to_date.to_s }
    let(:environment) { create(:environment, project: project, updated_at: 2.weeks.ago) }
    let!(:stale_deployment) { create(:deployment, environment: environment, updated_at: 2.weeks.ago) }

    it 'excludes environments with recent deployments' do
      create(:deployment, environment: environment, updated_at: Date.current)

      is_expected.to match_array([])
    end

    it 'includes environments with no deployments' do
      environment1 = create(:environment, project: project, updated_at: 2.weeks.ago)

      is_expected.to match_array([environment, environment1])
    end

    it 'excludes environments that have been recently updated with no deployments' do
      create(:environment, project: project)

      is_expected.to match_array([environment])
    end

    it 'excludes environments that have been recently updated with stale deployments' do
      environment1 = create(:environment, project: project)
      create(:deployment, environment: environment1, updated_at: 2.weeks.ago)

      is_expected.to match_array([environment])
    end
  end
end
