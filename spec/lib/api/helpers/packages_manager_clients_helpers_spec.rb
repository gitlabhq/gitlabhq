# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::PackagesManagerClientsHelpers do
  let_it_be(:personal_access_token) { create(:personal_access_token) }
  let_it_be(:username) { personal_access_token.user.username }
  let_it_be(:helper) { Class.new.include(described_class).new }
  let(:password) { personal_access_token.token }

  describe '#find_personal_access_token_from_http_basic_auth' do
    let(:headers) { { Authorization: basic_http_auth(username, password) } }

    subject { helper.find_personal_access_token_from_http_basic_auth }

    before do
      allow(helper).to receive(:headers).and_return(headers&.with_indifferent_access)
    end

    context 'with a valid Authorization header' do
      it { is_expected.to eq personal_access_token }
    end

    context 'with an invalid Authorization header' do
      where(:headers) do
        [
          [{ Authorization: 'Invalid' }],
          [{}],
          [nil]
        ]
      end

      with_them do
        it { is_expected.to be nil }
      end
    end

    context 'with an unknown Authorization header' do
      let(:password) { 'Unknown' }

      it { is_expected.to be nil }
    end
  end

  describe '#find_job_from_http_basic_auth' do
    let_it_be(:user) { personal_access_token.user }

    let(:job) { create(:ci_build, user: user) }
    let(:password) { job.token }
    let(:headers) { { Authorization: basic_http_auth(username, password) } }

    subject { helper.find_job_from_http_basic_auth }

    before do
      allow(helper).to receive(:headers).and_return(headers&.with_indifferent_access)
    end

    context 'with a valid Authorization header' do
      it { is_expected.to eq job }
    end

    context 'with an invalid Authorization header' do
      where(:headers) do
        [
          [{ Authorization: 'Invalid' }],
          [{}],
          [nil]
        ]
      end

      with_them do
        it { is_expected.to be nil }
      end
    end

    context 'with an unknown Authorization header' do
      let(:password) { 'Unknown' }

      it { is_expected.to be nil }
    end
  end

  describe '#find_deploy_token_from_http_basic_auth' do
    let_it_be(:deploy_token) { create(:deploy_token) }
    let(:token) { deploy_token.token }
    let(:headers) { { Authorization: basic_http_auth(deploy_token.username, token) } }

    subject { helper.find_deploy_token_from_http_basic_auth }

    before do
      allow(helper).to receive(:headers).and_return(headers&.with_indifferent_access)
    end

    context 'with a valid Authorization header' do
      it { is_expected.to eq deploy_token }
    end

    context 'with an invalid Authorization header' do
      where(:headers) do
        [
          [{ Authorization: 'Invalid' }],
          [{}],
          [nil]
        ]
      end

      with_them do
        it { is_expected.to be nil }
      end
    end

    context 'with an invalid token' do
      let(:token) { 'Unknown' }

      it { is_expected.to be nil }
    end
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

  def basic_http_auth(username, password)
    ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
  end
end
