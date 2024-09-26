# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::ProjectErrorTrackingSetting, feature_category: :observability do
  include ReactiveCachingHelpers
  include Gitlab::Routing

  let_it_be(:project) { create(:project) }

  let(:sentry_client) { instance_double(ErrorTracking::SentryClient) }

  let(:sentry_project_id) { 10 }

  subject(:setting) { build(:project_error_tracking_setting, project: project, sentry_project_id: sentry_project_id) }

  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'Validations' do
    it { is_expected.to validate_length_of(:api_url).is_at_most(255) }
    it { is_expected.to allow_value("http://gitlab.com/api/0/projects/project1/something").for(:api_url) }
    it { is_expected.not_to allow_values("http://gitlab.com/api/0/projects/project1/something€").for(:api_url) }

    it 'disallows non-booleans in enabled column' do
      is_expected.not_to allow_value(
        nil
      ).for(:enabled)
    end

    it 'allows booleans in enabled column' do
      is_expected.to allow_value(
        true,
        false
      ).for(:enabled)
    end

    it 'rejects invalid api_urls' do
      is_expected.not_to allow_values(
        "https://replaceme.com/'><script>alert(document.cookie)</script>", # unsafe
        "http://gitlab.com/project1/something", # missing api/0/projects
        "http://gitlab.com/api/0/projects/org/proj/something", # extra segments
        "http://gitlab.com/api/0/projects/org" # too few segments
      ).for(:api_url).with_message('is invalid')
    end

    it 'fails validation without org and project slugs' do
      subject.api_url = 'http://gitlab.com/api/0/projects/'

      expect(subject).not_to be_valid
      expect(subject.errors.messages[:project]).to include('is a required field')
    end

    describe 'presence validations' do
      using RSpec::Parameterized::TableSyntax

      valid_api_url = 'http://example.com/api/0/projects/org-slug/proj-slug/'
      valid_token = 'token'

      where(:enabled, :integrated, :token, :api_url, :valid?) do
        true  | true  | nil         | nil           | true
        true  | false | nil         | nil           | false
        true  | false | nil         | valid_api_url | false
        true  | false | valid_token | nil           | false
        true  | false | valid_token | valid_api_url | true
        false | false | nil         | nil           | true
        false | false | nil         | valid_api_url | true
        false | false | valid_token | nil           | true
        false | false | valid_token | valid_api_url | true
      end

      with_them do
        before do
          subject.enabled = enabled
          subject.integrated = integrated
          subject.token = token
          subject.api_url = api_url
        end

        it { expect(subject.valid?).to eq(valid?) }
      end
    end
  end

  describe 'Callbacks' do
    describe 'after_save :create_client_key!' do
      subject { build(:project_error_tracking_setting, :integrated, project: project) }

      context 'without client key' do
        it 'creates a new client key' do
          expect { subject.save! }.to change { ErrorTracking::ClientKey.count }.by(1)
        end

        context 'with sentry backend' do
          subject { build(:project_error_tracking_setting, project: project) }

          it 'does not create a new client key' do
            expect { subject.save! }.not_to change { ErrorTracking::ClientKey.count }
          end
        end

        context 'when feature disabled' do
          before do
            subject.enabled = false
          end

          it 'does not create a new client key' do
            expect { subject.save! }.not_to change { ErrorTracking::ClientKey.count }
          end
        end
      end

      context 'when client key already exists' do
        let!(:client_key) { create(:error_tracking_client_key, project: project) }

        it 'does not create a new client key' do
          expect { subject.save! }.not_to change { ErrorTracking::ClientKey.count }
        end
      end
    end

    describe 'before_validation :reset_token' do
      context 'when a token was previously set' do
        subject { create(:project_error_tracking_setting, project: project) }

        it 'resets token if url changed' do
          subject.api_url = 'http://sentry.com/api/0/projects/org-slug/proj-slug/'

          expect(subject).not_to be_valid
          expect(subject.token).to be_nil
        end

        it "does not reset token if new url is set together with the same token" do
          subject.api_url = 'http://sentrytest.com/api/0/projects/org-slug/proj-slug/'
          current_token = subject.token
          subject.token = current_token

          expect(subject).to be_valid
          expect(subject.token).to eq(current_token)
          expect(subject.api_url).to eq('http://sentrytest.com/api/0/projects/org-slug/proj-slug/')
        end

        it 'does not reset token if new url is set together with a new token' do
          subject.api_url = 'http://sentrytest.com/api/0/projects/org-slug/proj-slug/'
          subject.token = 'token'

          expect(subject).to be_valid
          expect(subject.token).to eq('token')
          expect(subject.api_url).to eq('http://sentrytest.com/api/0/projects/org-slug/proj-slug/')
        end
      end
    end
  end

  describe '.extract_sentry_external_url' do
    subject { described_class.extract_sentry_external_url(sentry_url) }

    context 'when passing a URL' do
      let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }

      it { is_expected.to eq('https://sentrytest.gitlab.com/sentry-org/sentry-project') }
    end

    context 'when passing nil' do
      let(:sentry_url) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#sentry_external_url' do
    let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }

    before do
      subject.api_url = sentry_url
    end

    it 'returns the correct url' do
      expect(subject.class).to receive(:extract_sentry_external_url).with(sentry_url).and_call_original

      result = subject.sentry_external_url

      expect(result).to eq('https://sentrytest.gitlab.com/sentry-org/sentry-project')
    end
  end

  describe '#sentry_client' do
    subject { setting.sentry_client }

    it { is_expected.to be_a(ErrorTracking::SentryClient) }
    it { is_expected.to have_attributes(url: setting.api_url, token: setting.token) }
  end

  describe '#list_sentry_issues' do
    let(:issues) { [:list, :of, :issues] }
    let(:result) { subject.list_sentry_issues(**opts) }
    let(:opts) { { issue_status: 'unresolved', limit: 10 } }

    context 'when cached' do
      before do
        stub_reactive_cache(subject, issues, opts)
        synchronous_reactive_cache(subject)

        allow(subject).to receive(:sentry_client).and_return(sentry_client)
      end

      it 'returns cached issues' do
        expect(sentry_client).to receive(:list_issues).with(opts)
          .and_return(issues: issues, pagination: {})

        expect(result).to eq(issues: issues, pagination: {})
      end
    end

    context 'when not cached' do
      it 'returns nil' do
        expect(subject).not_to receive(:sentry_client)

        expect(result).to be_nil
      end
    end

    describe 'client errors' do
      using RSpec::Parameterized::TableSyntax

      sc = ErrorTracking::SentryClient
      pets = described_class
      msg = 'something'

      before do
        synchronous_reactive_cache(subject)

        allow(subject).to receive(:sentry_client).and_return(sentry_client)
      end

      where(:exception, :error_type, :error_message) do
        sc::Error                    | pets::SENTRY_API_ERROR_TYPE_NON_20X_RESPONSE | msg
        sc::MissingKeysError         | pets::SENTRY_API_ERROR_TYPE_MISSING_KEYS     | msg
        sc::ResponseInvalidSizeError | pets::SENTRY_API_ERROR_INVALID_SIZE          | msg
        sc::BadRequestError          | pets::SENTRY_API_ERROR_TYPE_BAD_REQUEST      | msg
        StandardError                | nil                                          | 'Unexpected Error'
      end

      with_them do
        it 'returns an error' do
          allow(sentry_client).to receive(:list_issues).with(opts)
            .and_raise(exception, msg)

          expected_result = {
            error: error_message,
            error_type: error_type
          }.compact

          expect(result).to eq(expected_result)
        end
      end
    end
  end

  describe '#list_sentry_projects' do
    let(:projects) { [:list, :of, :projects] }

    it 'calls sentry client' do
      expect(subject).to receive(:sentry_client).and_return(sentry_client)
      expect(sentry_client).to receive(:projects).and_return(projects)

      result = subject.list_sentry_projects

      expect(result).to eq(projects: projects)
    end
  end

  describe '#issue_details' do
    let(:issue) { build(:error_tracking_sentry_detailed_error, project_id: sentry_project_id) }
    let(:commit_id) { issue.first_release_version }
    let(:result) { subject.issue_details(opts) }
    let(:opts) { { issue_id: 1 } }

    context 'when cached' do
      before do
        stub_reactive_cache(subject, issue, {})
        synchronous_reactive_cache(subject)

        allow(subject).to receive(:sentry_client).and_return(sentry_client)
        allow(sentry_client).to receive(:issue_details).with(opts).and_return(issue)
      end

      it { expect(result).to eq(issue: issue) }
      it { expect(result[:issue].first_release_version).to eq(commit_id) }
      it { expect(result[:issue].gitlab_commit).to eq(nil) }
      it { expect(result[:issue].gitlab_commit_path).to eq(nil) }

      context 'when release version is nil' do
        before do
          issue.first_release_version = nil
        end

        it { expect(result[:issue].gitlab_commit).to eq(nil) }
        it { expect(result[:issue].gitlab_commit_path).to eq(nil) }
      end

      context 'when repo commit matches first release version' do
        let(:commit) { instance_double(Commit, id: commit_id) }
        let(:repository) { instance_double(Repository, commit: commit) }

        before do
          allow(project).to receive(:repository).and_return(repository)
        end

        it { expect(result[:issue].gitlab_commit).to eq(commit_id) }
        it { expect(result[:issue].gitlab_commit_path).to eq(project_commit_path(project, commit_id)) }
      end
    end

    context 'when not cached' do
      it { expect(subject).not_to receive(:sentry_client) }
      it { expect(result).to be_nil }
    end
  end

  describe '#issue_latest_event' do
    let(:error_event) { build(:error_tracking_sentry_error_event, project_id: sentry_project_id) }
    let(:result) { subject.issue_latest_event(opts) }
    let(:opts) { { issue_id: 1 } }

    before do
      stub_reactive_cache(subject, error_event, {})
      synchronous_reactive_cache(subject)

      allow(subject).to receive(:sentry_client).and_return(sentry_client)
      allow(sentry_client).to receive(:issue_latest_event).with(opts).and_return(error_event)
    end

    it 'returns the error event' do
      expect(result[:latest_event].project_id).to eq(sentry_project_id)
    end
  end

  describe '#update_issue' do
    let(:result) { subject.update_issue(**opts) }
    let(:issue_id) { 1 }
    let(:opts) { { issue_id: issue_id, params: {} } }

    before do
      allow(subject).to receive(:sentry_client).and_return(sentry_client)
      allow(sentry_client).to receive(:issue_details)
        .with({ issue_id: issue_id })
        .and_return(Gitlab::ErrorTracking::DetailedError.new(project_id: sentry_project_id))
    end

    context 'when sentry response is successful' do
      before do
        allow(sentry_client).to receive(:update_issue).with(**opts).and_return(true)
      end

      it 'returns the successful response' do
        expect(result).to eq(updated: true)
      end
    end

    context 'when sentry raises an error' do
      before do
        allow(sentry_client).to receive(:update_issue).with(**opts).and_raise(StandardError)
      end

      it 'returns the successful response' do
        expect(result).to eq(error: 'Unexpected Error')
      end
    end

    context 'when sentry_project_id is not set' do
      let(:sentry_projects) do
        [
          Gitlab::ErrorTracking::Project.new(
            id: 1111,
            name: 'Some Project',
            organization_name: 'Org'
          ),
          Gitlab::ErrorTracking::Project.new(
            id: sentry_project_id,
            name: setting.project_name,
            organization_name: setting.organization_name
          )
        ]
      end

      context 'when sentry_project_id is not set' do
        before do
          setting.update!(sentry_project_id: nil)

          allow(sentry_client).to receive(:projects).and_return(sentry_projects)
          allow(sentry_client).to receive(:update_issue).with(**opts).and_return(true)
        end

        it 'tries to backfill it from sentry API' do
          expect(result).to eq(updated: true)

          expect(setting.reload.sentry_project_id).to eq(sentry_project_id)
        end

        context 'when the project cannot be found on sentry' do
          before do
            sentry_projects.pop
          end

          it 'raises error' do
            expect { result }.to raise_error(/Couldn't find project/)
          end
        end
      end

      context 'when mismatching sentry_project_id is detected' do
        it 'raises error' do
          setting.update!(sentry_project_id: sentry_project_id + 1)

          expect { result }.to raise_error(/The Sentry issue appers to be outside/)
        end
      end
    end

    describe 'passing parameters to sentry client' do
      include SentryClientHelpers

      let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0' }
      let(:sentry_request_url) { "#{sentry_url}/issues/#{issue_id}/" }
      let(:token) { 'test-token' }
      let(:sentry_client) { ErrorTracking::SentryClient.new(sentry_url, token) }

      before do
        stub_sentry_request(sentry_request_url, :put, body: true)

        allow(sentry_client).to receive(:update_issue).and_call_original
      end

      it 'returns the successful response' do
        expect(result).to eq(updated: true)
      end
    end
  end

  describe 'slugs' do
    shared_examples_for 'slug from api_url' do |method, slug|
      context 'when api_url is correct' do
        before do
          subject.api_url = 'http://gitlab.com/api/0/projects/org-slug/project-slug/'
        end

        it 'returns slug' do
          expect(subject.public_send(method)).to eq(slug)
        end
      end

      context 'when api_url is blank' do
        before do
          subject.api_url = nil
        end

        it 'returns nil' do
          expect(subject.public_send(method)).to be_nil
        end
      end
    end

    it_behaves_like 'slug from api_url', :project_slug, 'project-slug'
    it_behaves_like 'slug from api_url', :organization_slug, 'org-slug'
  end

  describe 'names from api_url' do
    shared_examples_for 'name from api_url' do |name, titleized_slug|
      context 'when name is present in DB' do
        it 'returns name from DB' do
          subject[name] = 'Sentry name'
          subject.api_url = 'http://gitlab.com/api/0/projects/org-slug/project-slug'

          expect(subject.public_send(name)).to eq('Sentry name')
        end
      end

      context 'when name is null in DB' do
        it 'titleizes and returns slug from api_url' do
          subject[name] = nil
          subject.api_url = 'http://gitlab.com/api/0/projects/org-slug/project-slug'

          expect(subject.public_send(name)).to eq(titleized_slug)
        end

        it 'returns nil when api_url is incorrect' do
          subject[name] = nil
          subject.api_url = 'http://gitlab.com/api/0/projects/'

          expect(subject.public_send(name)).to be_nil
        end

        it 'returns nil when api_url is blank' do
          subject[name] = nil
          subject.api_url = nil

          expect(subject.public_send(name)).to be_nil
        end
      end
    end

    it_behaves_like 'name from api_url', :organization_name, 'Org Slug'
    it_behaves_like 'name from api_url', :project_name, 'Project Slug'
  end

  describe '.build_api_url_from' do
    it 'correctly builds api_url with slugs' do
      api_url = described_class.build_api_url_from(
        api_host: 'http://sentry.com/',
        organization_slug: 'org-slug',
        project_slug: 'proj-slug'
      )

      expect(api_url).to eq('http://sentry.com/api/0/projects/org-slug/proj-slug/')
    end

    it 'correctly builds api_url without slugs' do
      api_url = described_class.build_api_url_from(
        api_host: 'http://sentry.com/',
        organization_slug: nil,
        project_slug: nil
      )

      expect(api_url).to eq('http://sentry.com/api/0/projects/')
    end

    it 'does not raise exception with invalid url' do
      api_url = described_class.build_api_url_from(
        api_host: ':::',
        organization_slug: 'org-slug',
        project_slug: 'proj-slug'
      )

      expect(api_url).to eq(':::')
    end

    it 'returns nil when api_host is blank' do
      api_url = described_class.build_api_url_from(
        api_host: '',
        organization_slug: 'org-slug',
        project_slug: 'proj-slug'
      )

      expect(api_url).to be_nil
    end
  end

  describe '#api_host' do
    context 'when api_url exists' do
      before do
        subject.api_url = 'https://example.com/api/0/projects/org-slug/proj-slug/'
      end

      it 'extracts the api_host from api_url' do
        expect(subject.api_host).to eq('https://example.com/')
      end
    end

    context 'when api_url is nil' do
      before do
        subject.api_url = nil
      end

      it 'returns nil' do
        expect(subject.api_url).to eq(nil)
      end
    end
  end

  describe '#expire_issues_cache', :use_clean_rails_redis_caching do
    let(:issues) { [:some, :issues] }
    let(:opt) { 'list_issues' }
    let(:params) { { issue_status: 'unresolved', limit: 20, sort: 'last_seen' } }

    before do
      start_reactive_cache_lifetime(subject, opt, params.stringify_keys)
      stub_reactive_cache(subject, issues, opt, params.stringify_keys)
    end

    it 'clears the cache' do
      expect(subject.list_sentry_issues(params)).to eq(issues)

      subject.expire_issues_cache

      expect(subject.list_sentry_issues(params)).to eq(nil)
    end
  end

  describe '#sentry_enabled' do
    using RSpec::Parameterized::TableSyntax

    where(:enabled, :integrated, :sentry_enabled) do
      true  | false | true
      true  | true  | false
      true  | true  | false
      false | false | false
    end

    with_them do
      before do
        subject.enabled = enabled
        subject.integrated = integrated
      end

      it { expect(subject.sentry_enabled).to eq(sentry_enabled) }
    end
  end

  describe '#integrated_enabled?' do
    using RSpec::Parameterized::TableSyntax

    where(:enabled, :integrated, :integrated_enabled) do
      true   | false | false
      false  | true  | false
      true   | true  | true
    end

    with_them do
      before do
        subject.enabled = enabled
        subject.integrated = integrated
      end

      it { expect(subject.integrated_enabled?).to eq(integrated_enabled) }
    end
  end

  describe '#gitlab_dsn' do
    let!(:client_key) { create(:error_tracking_client_key, project: project) }

    it { expect(subject.gitlab_dsn).to eq(client_key.sentry_dsn) }
  end
end
