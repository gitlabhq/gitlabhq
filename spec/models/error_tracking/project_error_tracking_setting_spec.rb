# frozen_string_literal: true

require 'spec_helper'

describe ErrorTracking::ProjectErrorTrackingSetting do
  include ReactiveCachingHelpers

  let_it_be(:project) { create(:project) }

  subject { create(:project_error_tracking_setting, project: project) }

  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'Validations' do
    it { is_expected.to validate_length_of(:api_url).is_at_most(255) }
    it { is_expected.to allow_value("http://gitlab.com/api/0/projects/project1/something").for(:api_url) }
    it { is_expected.not_to allow_values("http://gitlab.com/api/0/projects/project1/something€").for(:api_url) }

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

    context 'presence validations' do
      using RSpec::Parameterized::TableSyntax

      valid_api_url = 'http://example.com/api/0/projects/org-slug/proj-slug/'
      valid_token = 'token'

      where(:enabled, :token, :api_url, :valid?) do
        true  | nil         | nil           | false
        true  | nil         | valid_api_url | false
        true  | valid_token | nil           | false
        true  | valid_token | valid_api_url | true
        false | nil         | nil           | true
        false | nil         | valid_api_url | true
        false | valid_token | nil           | true
        false | valid_token | valid_api_url | true
      end

      with_them do
        before do
          subject.enabled = enabled
          subject.token = token
          subject.api_url = api_url
        end

        it { expect(subject.valid?).to eq(valid?) }
      end
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
    it 'returns sentry client' do
      expect(subject.sentry_client).to be_a(Sentry::Client)
    end
  end

  describe '#list_sentry_issues' do
    let(:issues) { [:list, :of, :issues] }

    let(:opts) do
      { issue_status: 'unresolved', limit: 10 }
    end

    let(:result) do
      subject.list_sentry_issues(**opts)
    end

    context 'when cached' do
      let(:sentry_client) { spy(:sentry_client) }

      before do
        stub_reactive_cache(subject, issues, opts)
        synchronous_reactive_cache(subject)

        expect(subject).to receive(:sentry_client).and_return(sentry_client)
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

    context 'when sentry client raises Sentry::Client::Error' do
      let(:sentry_client) { spy(:sentry_client) }

      before do
        synchronous_reactive_cache(subject)

        allow(subject).to receive(:sentry_client).and_return(sentry_client)
        allow(sentry_client).to receive(:list_issues).with(opts)
          .and_raise(Sentry::Client::Error, 'error message')
      end

      it 'returns error' do
        expect(result).to eq(
          error: 'error message',
          error_type: ErrorTracking::ProjectErrorTrackingSetting::SENTRY_API_ERROR_TYPE_NON_20X_RESPONSE
        )
      end
    end

    context 'when sentry client raises Sentry::Client::MissingKeysError' do
      let(:sentry_client) { spy(:sentry_client) }

      before do
        synchronous_reactive_cache(subject)

        allow(subject).to receive(:sentry_client).and_return(sentry_client)
        allow(sentry_client).to receive(:list_issues).with(opts)
          .and_raise(Sentry::Client::MissingKeysError, 'Sentry API response is missing keys. key not found: "id"')
      end

      it 'returns error' do
        expect(result).to eq(
          error: 'Sentry API response is missing keys. key not found: "id"',
          error_type: ErrorTracking::ProjectErrorTrackingSetting::SENTRY_API_ERROR_TYPE_MISSING_KEYS
        )
      end
    end

    context 'when sentry client raises Sentry::Client::ResponseInvalidSizeError' do
      let(:sentry_client) { spy(:sentry_client) }
      let(:error_msg) {"Sentry API response is too big. Limit is #{Gitlab::Utils::DeepSize.human_default_max_size}."}

      before do
        synchronous_reactive_cache(subject)

        allow(subject).to receive(:sentry_client).and_return(sentry_client)
        allow(sentry_client).to receive(:list_issues).with(opts)
          .and_raise(Sentry::Client::ResponseInvalidSizeError, error_msg)
      end

      it 'returns error' do
        expect(result).to eq(
          error: error_msg,
          error_type: ErrorTracking::ProjectErrorTrackingSetting::SENTRY_API_ERROR_INVALID_SIZE
        )
      end
    end

    context 'when sentry client raises StandardError' do
      let(:sentry_client) { spy(:sentry_client) }

      before do
        synchronous_reactive_cache(subject)

        allow(subject).to receive(:sentry_client).and_return(sentry_client)
        allow(sentry_client).to receive(:list_issues).with(opts).and_raise(StandardError)
      end

      it 'returns error' do
        expect(result).to eq(error: 'Unexpected Error')
      end
    end
  end

  describe '#list_sentry_projects' do
    let(:projects) { [:list, :of, :projects] }
    let(:sentry_client) { spy(:sentry_client) }

    it 'calls sentry client' do
      expect(subject).to receive(:sentry_client).and_return(sentry_client)
      expect(sentry_client).to receive(:projects).and_return(projects)

      result = subject.list_sentry_projects

      expect(result).to eq(projects: projects)
    end
  end

  describe '#issue_details' do
    let(:issue) { build(:detailed_error_tracking_error) }
    let(:sentry_client) { double('sentry_client', issue_details: issue) }
    let(:commit_id) { '123456' }

    let(:result) do
      subject.issue_details
    end

    context 'when cached' do
      before do
        stub_reactive_cache(subject, issue, {})
        synchronous_reactive_cache(subject)

        expect(subject).to receive(:sentry_client).and_return(sentry_client)
      end

      it { expect(result).to eq(issue: issue) }
      it { expect(result[:issue].first_release_version).to eq(commit_id) }
      it { expect(result[:issue].gitlab_commit).to eq(nil) }

      context 'when release version is nil' do
        before do
          issue.first_release_version = nil
        end

        it { expect(result[:issue].gitlab_commit).to eq(nil) }
      end

      context 'when repo commit matches first relase version' do
        let(:commit) { double('commit', id: commit_id) }
        let(:repository) { double('repository', commit: commit) }

        before do
          expect(project).to receive(:repository).and_return(repository)
        end

        it { expect(result[:issue].gitlab_commit).to eq(commit_id) }
      end
    end

    context 'when not cached' do
      it { expect(subject).not_to receive(:sentry_client) }
      it { expect(result).to be_nil }
    end
  end

  describe '#update_issue' do
    let(:opts) do
      { status: 'resolved' }
    end

    let(:result) do
      subject.update_issue(**opts)
    end

    let(:sentry_client) { spy(:sentry_client) }

    context 'successful call to sentry' do
      before do
        allow(subject).to receive(:sentry_client).and_return(sentry_client)
        allow(sentry_client).to receive(:update_issue).with(opts).and_return(true)
      end

      it 'returns the successful response' do
        expect(result).to eq(updated: true)
      end
    end

    context 'sentry raises an error' do
      before do
        allow(subject).to receive(:sentry_client).and_return(sentry_client)
        allow(sentry_client).to receive(:update_issue).with(opts).and_raise(StandardError)
      end

      it 'returns the successful response' do
        expect(result).to eq(error: 'Unexpected Error')
      end
    end
  end

  context 'slugs' do
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

  context 'names from api_url' do
    shared_examples_for 'name from api_url' do |name, titleized_slug|
      context 'name is present in DB' do
        it 'returns name from DB' do
          subject[name] = 'Sentry name'
          subject.api_url = 'http://gitlab.com/api/0/projects/org-slug/project-slug'

          expect(subject.public_send(name)).to eq('Sentry name')
        end
      end

      context 'name is null in DB' do
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
end
