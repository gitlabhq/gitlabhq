# frozen_string_literal: true

require 'securerandom'

require 'spec_helper'

RSpec.describe Integrations::Datadog, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user, username: 'username') }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:build) { create(:ci_build, pipeline: pipeline) }
  let_it_be(:retried_build) { create(:ci_build, :retried, pipeline: pipeline) }

  let(:active) { true }
  let(:dd_site) { 'datadoghq.com' }
  let(:default_url) { 'https://webhook-intake.datadoghq.com/api/v2/webhook' }
  let(:api_url) { '' }
  let(:api_key) { SecureRandom.hex(32) }
  let(:dd_env) { 'ci' }
  let(:dd_service) { 'awesome-gitlab' }
  let(:dd_tags) { '' }
  let(:dd_ci_visibility) { nil }

  let(:expected_hook_url) { default_url + "?dd-api-key=#{api_key}&env=#{dd_env}&service=#{dd_service}" }
  let(:hook_url) { default_url + "?dd-api-key={api_key}&env=#{dd_env}&service=#{dd_service}" }

  let(:instance) do
    described_class.new(
      active: active,
      project: project,
      datadog_site: dd_site,
      api_url: api_url,
      api_key: api_key,
      datadog_env: dd_env,
      datadog_service: dd_service,
      datadog_tags: dd_tags,
      datadog_ci_visibility: dd_ci_visibility
    )
  end

  let(:saved_instance) do
    instance.save!
    instance
  end

  let(:pipeline_data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }
  let(:build_data) { Gitlab::DataBuilder::Build.build(build) }
  let(:push_data) { Gitlab::DataBuilder::Push.build_sample(project, user) }
  let(:archive_trace_data) do
    create(:ci_job_artifact, :trace, job: build)

    Gitlab::DataBuilder::ArchiveTrace.build(build)
  end

  it_behaves_like Integrations::ResetSecretFields do
    let(:integration) { instance }
  end

  it_behaves_like Integrations::HasWebHook do
    let(:integration) { instance }
    let(:hook_url) { "#{described_class::URL_TEMPLATE % { datadog_domain: dd_site }}?dd-api-key={api_key}&env=#{dd_env}&service=#{dd_service}" }
  end

  it_behaves_like Integrations::HasAvatar

  describe 'validations' do
    subject { instance }

    context 'when service is active' do
      let(:active) { true }

      it { is_expected.to validate_presence_of(:api_key) }
      it { is_expected.to allow_value(api_key).for(:api_key) }
      it { is_expected.not_to allow_value('87dab2403c9d462 87aec4d9214edb1e').for(:api_key) }
      it { is_expected.not_to allow_value('................................').for(:api_key) }

      context 'when selecting site' do
        let(:dd_site) { 'datadoghq.com' }
        let(:api_url) { '' }

        it { is_expected.to validate_presence_of(:datadog_site) }
        it { is_expected.not_to validate_presence_of(:api_url) }
        it { is_expected.to allow_value('data-dog-hq.com').for(:datadog_site) }
        it { is_expected.to allow_value('dataDOG.com').for(:datadog_site) }
        it { is_expected.not_to allow_value('datadog hq.com').for(:datadog_site) }
        it { is_expected.not_to allow_value('-datadoghq.com').for(:datadog_site) }
        it { is_expected.not_to allow_value('.datadoghq.com').for(:datadog_site) }
        it { is_expected.not_to allow_value('datadoghq.com_').for(:datadog_site) }
        it { is_expected.not_to allow_value('data-dog').for(:datadog_site) }
        it { is_expected.not_to allow_value('datadoghq.com-').for(:datadog_site) }
        it { is_expected.not_to allow_value('datadoghq.com.').for(:datadog_site) }
      end

      context 'with custom api_url' do
        let(:dd_site) { '' }
        let(:api_url) { 'https://webhook-intake.datad0g.com/api/v2/webhook' }

        it { is_expected.not_to validate_presence_of(:datadog_site) }
        it { is_expected.to validate_presence_of(:api_url) }
        it { is_expected.to allow_value(api_url).for(:api_url) }
        it { is_expected.not_to allow_value('example.com').for(:api_url) }
      end

      context 'when missing site and api_url' do
        let(:dd_site) { '' }
        let(:api_url) { '' }

        it { is_expected.not_to be_valid }
        it { is_expected.to validate_presence_of(:datadog_site) }
        it { is_expected.to validate_presence_of(:api_url) }
      end

      context 'when providing both site and api_url' do
        let(:dd_site) { 'datadoghq.com' }
        let(:api_url) { default_url }

        it { is_expected.not_to allow_value('datadog hq.com').for(:datadog_site) }
        it { is_expected.not_to allow_value('example.com').for(:api_url) }
      end

      context 'with custom tags' do
        it { is_expected.to allow_value('').for(:datadog_tags) }
        it { is_expected.to allow_value('key:value').for(:datadog_tags) }
        it { is_expected.to allow_value("key:value\nkey2:value2").for(:datadog_tags) }
        it { is_expected.to allow_value("key:value\nkey2:value with spaces and 123?&$").for(:datadog_tags) }
        it { is_expected.to allow_value("key:value\n\n\n\nkey2:value2\n").for(:datadog_tags) }

        it { is_expected.not_to allow_value('value').for(:datadog_tags) }
        it { is_expected.not_to allow_value('key:').for(:datadog_tags) }
        it { is_expected.not_to allow_value('key:   ').for(:datadog_tags) }
        it { is_expected.not_to allow_value(':value').for(:datadog_tags) }
        it { is_expected.not_to allow_value("key:value\nINVALID").for(:datadog_tags) }
      end

      context 'with datadog_ci_visibility disabled' do
        let(:dd_ci_visibility) { false }

        it { is_expected.to allow_value(false).for(:archive_trace_events) }

        it 'syncs archive_trace_events to false instead of raising a validation error' do
          instance.archive_trace_events = true

          expect(instance).to be_valid
          expect(instance.archive_trace_events).to be(false)
        end
      end

      context 'with datadog_ci_visibility enabled' do
        let(:dd_ci_visibility) { true }

        it { is_expected.to allow_value(true).for(:archive_trace_events) }
        it { is_expected.to allow_value(false).for(:archive_trace_events) }
      end
    end

    context 'when integration is not active' do
      let(:active) { false }

      it { is_expected.to be_valid }
      it { is_expected.not_to validate_presence_of(:api_key) }
    end
  end

  describe '.help' do
    it 'links to the help page correctly' do
      expect(described_class.help).to include('help/integration/datadog.md', 'How do I set up this integration?')
    end
  end

  describe 'upgrade from previous version' do
    subject { instance.datadog_ci_visibility }

    let(:instance) do
      described_class.instantiate(
        'id' => non_existing_record_id,
        'project_id' => project.id,
        'active' => active,
        'type_new' => 'Integrations::Datadog',
        'encrypted_properties' => nil,
        'encrypted_properties_iv' => nil
      )
    end

    context 'with previously active integration' do
      let(:active) { true }

      # If the integration was active but no datadog_ci_visibility is in the
      # properties, we're expecting it to be true since this was the previous default
      it { is_expected.to be(true) }
    end

    context 'with previously inactive integration' do
      let(:active) { false }

      # If the integration is not active, datadog_ci_visibility shouldn't be initialized
      # since it's now opt-in
      it { is_expected.to be(false) }
    end
  end

  describe 'initial setup' do
    let(:active) { false }
    let(:dd_ci_visibility) { nil }

    it 'defaults CI Visibility to enabled' do
      expect(instance.datadog_ci_visibility).to be(true)
    end

    it 'defaults log pulling to enabled' do
      expect(instance.archive_trace_events).to be(true)
    end

    it 'hides log pulling until the integration is saved' do
      expect(instance.form_fields.pluck(:name)).not_to include('archive_trace_events')
    end

    it 'does not override an explicitly set value while CI Visibility is enabled' do
      instance.archive_trace_events = false

      expect(instance).to be_valid
      expect(instance.archive_trace_events).to be(false)
    end

    it 'shows log pulling after the integration is saved' do
      instance.save!

      expect(instance.form_fields.pluck(:name)).to include('archive_trace_events')
    end

    context 'when CI Visibility is explicitly disabled' do
      let(:dd_ci_visibility) { false }

      it 'defaults log pulling to disabled' do
        expect(instance.archive_trace_events).to be(false)
      end

      it 'keeps log pulling disabled during validation' do
        instance.archive_trace_events = true

        expect { instance.valid? }.to change { instance.archive_trace_events }.from(true).to(false)
      end
    end

    context 'when activating the integration on first save with CI Visibility disabled' do
      let(:active) { true }
      let(:dd_ci_visibility) { false }

      it 'keeps log pulling in sync with CI Visibility instead of raising a validation error' do
        instance.archive_trace_events = true

        expect(instance).to be_valid
        expect(instance.archive_trace_events).to be(false)
      end
    end

    context 'when the integration is built and then activated in a separate step' do
      it 'keeps log pulling in sync with the final CI Visibility value on save' do
        integration = described_class.new(project: project)

        integration.assign_attributes(
          active: true,
          api_key: api_key,
          datadog_site: dd_site,
          datadog_ci_visibility: false
        )

        expect(integration).to be_valid
        expect(integration.archive_trace_events).to be(false)
      end
    end

    context 'once the integration has already been saved' do
      let(:active) { true }
      let(:dd_ci_visibility) { true }

      it 'no longer syncs log pulling with CI Visibility on later edits' do
        saved_instance.update!(archive_trace_events: false)

        expect { saved_instance.update!(datadog_ci_visibility: false) }
          .not_to change { saved_instance.archive_trace_events }
      end

      it 'raises a validation error when only disabling CI Visibility while log pulling stays enabled' do
        saved_instance # both start enabled by default

        expect(saved_instance.archive_trace_events).to be(true)
        expect(saved_instance.update(datadog_ci_visibility: false)).to be(false)
        expect(saved_instance.errors[:archive_trace_events]).to include('requires CI Visibility to be enabled')
      end
    end
  end

  describe '#hook_url' do
    subject { instance.hook_url }

    context 'with standard site URL' do
      it { is_expected.to eq(hook_url) }
    end

    context 'with custom URL' do
      let(:api_url) { 'https://webhook-intake.datad0g.com/api/v2/webhook' }

      it { is_expected.to eq(api_url + "?dd-api-key={api_key}&env=#{dd_env}&service=#{dd_service}") }

      context 'blank' do
        let(:api_url) { '' }

        it { is_expected.to eq(hook_url) }
      end
    end

    context 'without optional params' do
      let(:dd_service) { '' }
      let(:dd_env) { '' }
      let(:dd_tags) { '' }

      it { is_expected.to eq(default_url + "?dd-api-key={api_key}") }
    end

    context 'with custom tags' do
      let(:dd_tags) { "key:value\nkey2:value, 2" }
      let(:escaped_tags) { CGI.escape("key:value,\"key2:value, 2\"") }

      it { is_expected.to eq(hook_url + "&tags=#{escaped_tags}") }

      context 'and empty lines' do
        let(:dd_tags) { "key:value\r\n\n\n\nkey2:value, 2\n" }

        it { is_expected.to eq(hook_url + "&tags=#{escaped_tags}") }
      end
    end
  end

  describe '#test' do
    subject(:result) { saved_instance.test(pipeline_data) }

    let(:body) { 'OK' }
    let(:status) { 200 }

    before do
      stub_request(:post, expected_hook_url).to_return(body: body, status: status)
    end

    context 'when request is successful with a HTTP 200 status' do
      it { is_expected.to eq({ success: true, result: 'OK' }) }
    end

    context 'when request is successful with a HTTP 202 status' do
      let(:status) { 202 }

      it { is_expected.to eq({ success: true, result: 'OK' }) }
    end

    context 'when request fails with a HTTP 500 status' do
      let(:status) { 500 }
      let(:body) { 'CRASH!!!' }

      it { is_expected.to eq({ success: false, result: 'CRASH!!!' }) }
    end
  end

  describe '#execute' do
    around do |example|
      freeze_time { example.run }
    end

    before do
      stub_request(:post, expected_hook_url)
      saved_instance.execute(data)
    end

    context 'with pipeline data' do
      let(:data) { pipeline_data }
      let(:expected_headers) { { ::Gitlab::WebHooks::GITLAB_EVENT_HEADER => 'Pipeline Hook' } }
      let(:expected_body) { data.with_retried_builds.to_json }

      it { expect(a_request(:post, expected_hook_url).with(headers: expected_headers, body: expected_body)).to have_been_made }
    end

    context 'with job data' do
      let(:data) { build_data }
      let(:expected_headers) { { ::Gitlab::WebHooks::GITLAB_EVENT_HEADER => 'Job Hook' } }
      let(:expected_body) { data.to_json }

      it { expect(a_request(:post, expected_hook_url).with(headers: expected_headers, body: expected_body)).to have_been_made }
    end

    context 'with archive trace data' do
      let(:data) { archive_trace_data }
      let(:expected_headers) { { ::Gitlab::WebHooks::GITLAB_EVENT_HEADER => 'Archive Trace Hook' } }
      let(:expected_body) { data.to_json }

      it { expect(a_request(:post, expected_hook_url).with(headers: expected_headers, body: expected_body)).to have_been_made }
    end

    context 'with push data' do
      let(:data) { push_data }
      let(:expected_headers) { { ::Gitlab::WebHooks::GITLAB_EVENT_HEADER => 'Push Hook' } }
      let(:expected_body) { data.to_json }

      it { expect(a_request(:post, expected_hook_url).with(headers: expected_headers, body: expected_body)).to have_been_made }
    end
  end
end
