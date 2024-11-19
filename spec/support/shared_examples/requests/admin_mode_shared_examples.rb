# frozen_string_literal: true

RSpec.shared_examples 'DELETE request permissions for admin mode' do
  subject { delete api(path, current_user, admin_mode: admin_mode) }

  let_it_be(:user_organizations) do
    Array(defined?(current_organization) ? current_organization : create(:organization))
  end

  let_it_be(:success_status_code) { :no_content }
  let_it_be(:failed_status_code) { :forbidden }

  it_behaves_like 'when admin'
  it_behaves_like 'when user'
end

RSpec.shared_examples 'GET request permissions for admin mode' do
  subject { get api(path, current_user, admin_mode: admin_mode) }

  let_it_be(:user_organizations) do
    Array(defined?(current_organization) ? current_organization : create(:organization))
  end

  let_it_be(:success_status_code) { :ok }
  let_it_be(:failed_status_code) { :forbidden }

  it_behaves_like 'when admin'
  it_behaves_like 'when user'
end

RSpec.shared_examples 'PUT request permissions for admin mode' do
  subject { put api(path, current_user, admin_mode: admin_mode), params: params }

  let_it_be(:user_organizations) do
    Array(defined?(current_organization) ? current_organization : create(:organization))
  end

  let_it_be(:success_status_code) { :ok }
  let_it_be(:failed_status_code) { :forbidden }

  it_behaves_like 'when admin'
  it_behaves_like 'when user'
end

RSpec.shared_examples 'POST request permissions for admin mode' do
  subject { post api(path, current_user, admin_mode: admin_mode), params: params }

  let_it_be(:user_organizations) do
    Array(defined?(current_organization) ? current_organization : create(:organization))
  end

  let_it_be(:success_status_code) { :created }
  let_it_be(:failed_status_code) { :forbidden }

  it_behaves_like 'when admin'
  it_behaves_like 'when user'
end

RSpec.shared_examples 'when user' do
  let_it_be(:current_user) { create(:user, organizations: user_organizations) }

  include_examples 'makes request' do
    let(:status) { failed_status_code }
    let(:admin_mode) { true }
  end

  it_behaves_like 'makes request' do
    let(:status) { failed_status_code }
    let(:admin_mode) { false }
  end
end

RSpec.shared_examples 'when admin' do
  let_it_be(:current_user) { create(:admin, organizations: user_organizations) }

  it_behaves_like 'makes request' do
    let(:status) { success_status_code }
    let(:admin_mode) { true }
  end

  it_behaves_like 'makes request' do
    let(:status) { failed_status_code }
    let(:admin_mode) { false }
  end
end

RSpec.shared_examples "makes request" do
  let_it_be(:status) { nil }

  it "returns" do
    subject

    expect(response).to have_gitlab_http_status(status)
  end
end
