# frozen_string_literal: true
RSpec.shared_examples 'GET request permissions for admin mode' do
  it_behaves_like 'GET request permissions for admin mode when user'
  it_behaves_like 'GET request permissions for admin mode when admin'
end

RSpec.shared_examples 'PUT request permissions for admin mode' do |params|
  it_behaves_like 'PUT request permissions for admin mode when user', params
  it_behaves_like 'PUT request permissions for admin mode when admin', params
end

RSpec.shared_examples 'POST request permissions for admin mode' do |params|
  it_behaves_like 'POST request permissions for admin mode when user', params
  it_behaves_like 'POST request permissions for admin mode when admin', params
end

RSpec.shared_examples 'DELETE request permissions for admin mode' do |success_status_code = :no_content|
  it_behaves_like 'DELETE request permissions for admin mode when user'
  it_behaves_like 'DELETE request permissions for admin mode when admin', success_status_code
end

RSpec.shared_examples 'GET request permissions for admin mode when user' do
  subject { get api(path, current_user, admin_mode: admin_mode) }

  let_it_be(:current_user) { create(:user) }

  it_behaves_like 'admin mode on', true, :forbidden
  it_behaves_like 'admin mode on', false, :forbidden
end

RSpec.shared_examples 'GET request permissions for admin mode when admin' do
  subject { get api(path, current_user, admin_mode: admin_mode) }

  let_it_be(:current_user) { create(:admin) }

  it_behaves_like 'admin mode on', true, :ok
  it_behaves_like 'admin mode on', false, :forbidden
end

RSpec.shared_examples 'PUT request permissions for admin mode when user' do |params|
  subject { put api(path, current_user, admin_mode: admin_mode), params: params }

  let_it_be(:current_user) { create(:user) }

  it_behaves_like 'admin mode on', true, :forbidden
  it_behaves_like 'admin mode on', false, :forbidden
end

RSpec.shared_examples 'PUT request permissions for admin mode when admin' do |params|
  subject { put api(path, current_user, admin_mode: admin_mode), params: params }

  let_it_be(:current_user) { create(:admin) }

  it_behaves_like 'admin mode on', true, :ok
  it_behaves_like 'admin mode on', false, :forbidden
end

RSpec.shared_examples 'POST request permissions for admin mode when user' do |params|
  subject { post api(path, current_user, admin_mode: admin_mode), params: params }

  let_it_be(:current_user) { create(:user) }

  it_behaves_like 'admin mode on', true, :forbidden
  it_behaves_like 'admin mode on', false, :forbidden
end

RSpec.shared_examples 'POST request permissions for admin mode when admin' do |params|
  subject { post api(path, current_user, admin_mode: admin_mode), params: params }

  let_it_be(:current_user) { create(:admin) }

  it_behaves_like 'admin mode on', true, :created
  it_behaves_like 'admin mode on', false, :forbidden
end

RSpec.shared_examples 'DELETE request permissions for admin mode when user' do
  subject { delete api(path, current_user, admin_mode: admin_mode) }

  let_it_be(:current_user) { create(:user) }

  it_behaves_like 'admin mode on', true, :forbidden
  it_behaves_like 'admin mode on', false, :forbidden
end

RSpec.shared_examples 'DELETE request permissions for admin mode when admin' do |success_status_code|
  subject { delete api(path, current_user, admin_mode: admin_mode) }

  let_it_be(:current_user) { create(:admin) }

  it_behaves_like 'admin mode on', true, success_status_code
  it_behaves_like 'admin mode on', false, :forbidden
end

RSpec.shared_examples "admin mode on" do |admin_mode, status|
  let_it_be(:admin_mode) { admin_mode }

  it_behaves_like 'returning response status', status
end
