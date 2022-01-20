# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackAttack::Request do
  using RSpec::Parameterized::TableSyntax

  let(:env) { {} }
  let(:session) { {} }
  let(:request) do
    ::Rack::Attack::Request.new(
      env.reverse_merge(
        'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => path,
        'rack.input' => StringIO.new,
        'rack.session' => session
      )
    )
  end

  describe 'FILES_PATH_REGEX' do
    subject { described_class::FILES_PATH_REGEX }

    it { is_expected.to match('/api/v4/projects/1/repository/files/README') }
    it { is_expected.to match('/api/v4/projects/1/repository/files/README?ref=master') }
    it { is_expected.to match('/api/v4/projects/1/repository/files/README/blame') }
    it { is_expected.to match('/api/v4/projects/1/repository/files/README/raw') }
    it { is_expected.to match('/api/v4/projects/some%2Fnested%2Frepo/repository/files/README') }
    it { is_expected.not_to match('/api/v4/projects/some/nested/repo/repository/files/README') }
  end

  describe '#api_request?' do
    subject { request.api_request? }

    where(:path, :expected) do
      '/'       | false
      '/groups' | false

      '/api'             | true
      '/api/v4/groups/1' | true
    end

    with_them do
      it { is_expected.to eq(expected) }
    end
  end

  describe '#web_request?' do
    subject { request.web_request? }

    where(:path, :expected) do
      '/'       | true
      '/groups' | true

      '/api'             | false
      '/api/v4/groups/1' | false
    end

    with_them do
      it { is_expected.to eq(expected) }
    end
  end

  describe '#frontend_request?', :allow_forgery_protection do
    subject { request.send(:frontend_request?) }

    let(:path) { '/' }

    # Define these as local variables so we can use them in the `where` block.
    valid_token = SecureRandom.base64(ActionController::RequestForgeryProtection::AUTHENTICITY_TOKEN_LENGTH)
    other_token = SecureRandom.base64(ActionController::RequestForgeryProtection::AUTHENTICITY_TOKEN_LENGTH)

    where(:session, :env, :expected) do
      {}                           | {}                                     | false # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands
      {}                           | { 'HTTP_X_CSRF_TOKEN' => valid_token } | false
      { _csrf_token: valid_token } | { 'HTTP_X_CSRF_TOKEN' => other_token } | false
      { _csrf_token: valid_token } | { 'HTTP_X_CSRF_TOKEN' => valid_token } | true
    end

    with_them do
      it { is_expected.to eq(expected) }
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(rate_limit_frontend_requests: false)
      end

      where(:session, :env) do
        {}                           | {} # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands
        {}                           | { 'HTTP_X_CSRF_TOKEN' => valid_token }
        { _csrf_token: valid_token } | { 'HTTP_X_CSRF_TOKEN' => other_token }
        { _csrf_token: valid_token } | { 'HTTP_X_CSRF_TOKEN' => valid_token }
      end

      with_them do
        it { is_expected.to be(false) }
      end
    end
  end

  describe '#deprecated_api_request?' do
    subject { request.send(:deprecated_api_request?) }

    let(:env) { { 'QUERY_STRING' => query } }

    where(:path, :query, :expected) do
      '/' | '' | false

      '/api/v4/groups/1/'   | '' | true
      '/api/v4/groups/1'    | '' | true
      '/api/v4/groups/foo/' | '' | true
      '/api/v4/groups/foo'  | '' | true

      '/api/v4/groups/1'  | 'with_projects='  | true
      '/api/v4/groups/1'  | 'with_projects=1' | true
      '/api/v4/groups/1'  | 'with_projects=0' | false

      '/foo/api/v4/groups/1' | '' | false
      '/api/v4/groups/1/foo' | '' | false

      '/api/v4/groups/nested%2Fgroup' | '' | true
    end

    with_them do
      it { is_expected.to eq(expected) }
    end
  end
end
