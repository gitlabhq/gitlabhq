# frozen_string_literal: true

RSpec.shared_examples 'disabled virtual_registry_maven feature flag' do
  before do
    stub_feature_flags(virtual_registry_maven: false)
  end

  it_behaves_like 'returning response status', :not_found
end

RSpec.shared_examples 'maven virtual registry disabled dependency proxy' do
  before do
    stub_config(dependency_proxy: { enabled: false })
  end

  it_behaves_like 'returning response status', :not_found
end

RSpec.shared_examples 'maven virtual registry not authenticated user' do
  let(:headers) { {} }

  it_behaves_like 'returning response status', :unauthorized
end

RSpec.shared_examples 'maven virtual registry authenticated endpoint' do |success_shared_example_name:|
  %i[personal_access_token deploy_token job_token].each do |token_type|
    context "with a #{token_type}" do
      let_it_be(:user) { deploy_token } if token_type == :deploy_token

      context 'when sent by headers' do
        let(:headers) { super().merge(token_header(token_type)) }

        it_behaves_like success_shared_example_name
      end

      context 'when sent by basic auth' do
        let(:headers) { super().merge(token_basic_auth(token_type)) }

        it_behaves_like success_shared_example_name
      end
    end
  end
end
