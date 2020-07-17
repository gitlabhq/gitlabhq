# frozen_string_literal: true

RSpec.shared_examples 'deploy token for package GET requests' do
  context 'with deploy token headers' do
    let(:headers) { build_basic_auth_header(deploy_token.username, deploy_token.token) }

    subject { get api(url), headers: headers }

    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    end

    context 'valid token' do
      it_behaves_like 'returning response status', :success
    end

    context 'invalid token' do
      let(:headers) { build_basic_auth_header(deploy_token.username, 'bar') }

      it_behaves_like 'returning response status', :unauthorized
    end
  end
end

RSpec.shared_examples 'deploy token for package uploads' do
  context 'with deploy token headers' do
    let(:headers) { build_basic_auth_header(deploy_token.username, deploy_token.token).merge(workhorse_header) }

    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    end

    context 'valid token' do
      it_behaves_like 'returning response status', :success
    end

    context 'invalid token' do
      let(:headers) { build_basic_auth_header(deploy_token.username, 'bar').merge(workhorse_header) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end
end
