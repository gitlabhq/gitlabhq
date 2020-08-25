# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::PackagesManagerClientsHelpers do
  include HttpBasicAuthHelpers

  let_it_be(:personal_access_token) { create(:personal_access_token) }
  let_it_be(:username) { personal_access_token.user.username }
  let_it_be(:helper) { Class.new.include(described_class).new }
  let(:password) { personal_access_token.token }

  let(:env) do
    {
      'rack.input' => ''
    }
  end

  let(:request) { ActionDispatch::Request.new(env) }

  before do
    allow(helper).to receive(:request).and_return(request)
  end

  shared_examples 'invalid auth header' do
    context 'with an invalid Authorization header' do
      before do
        env.merge!(build_auth_headers('Invalid'))
      end

      it { is_expected.to be nil }
    end
  end

  shared_examples 'valid auth header' do
    context 'with a valid Authorization header' do
      before do
        env.merge!(basic_auth_header(username, password))
      end

      context 'with an unknown password' do
        let(:password) { 'Unknown' }

        it { is_expected.to be nil }
      end

      it { is_expected.to eq expected_result }
    end
  end

  describe '#find_job_from_http_basic_auth' do
    let_it_be(:user) { personal_access_token.user }
    let(:job) { create(:ci_build, user: user) }
    let(:password) { job.token }

    subject { helper.find_job_from_http_basic_auth }

    it_behaves_like 'valid auth header' do
      let(:expected_result) { job }
    end

    it_behaves_like 'invalid auth header'
  end

  describe '#find_deploy_token_from_http_basic_auth' do
    let_it_be(:deploy_token) { create(:deploy_token) }
    let(:token) { deploy_token.token }
    let(:username) { deploy_token.username }
    let(:password) { token }

    subject { helper.find_deploy_token_from_http_basic_auth }

    it_behaves_like 'valid auth header' do
      let(:expected_result) { deploy_token }
    end

    it_behaves_like 'invalid auth header'
  end

  describe '#uploaded_package_file' do
    let_it_be(:params) { {} }

    subject { helper.uploaded_package_file }

    before do
      allow(helper).to receive(:params).and_return(params)
    end

    context 'with valid uploaded package file' do
      let_it_be(:uploaded_file) { Object.new }

      before do
        allow(UploadedFile).to receive(:from_params).and_return(uploaded_file)
      end

      it { is_expected.to be uploaded_file }
    end

    context 'with invalid uploaded package file' do
      before do
        allow(UploadedFile).to receive(:from_params).and_return(nil)
      end

      it 'fails with bad_request!' do
        expect(helper).to receive(:bad_request!)

        expect(subject).to be nil
      end
    end
  end
end
