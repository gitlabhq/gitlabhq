# frozen_string_literal: true

RSpec.shared_context 'Debian repository shared context' do |container_type, can_freeze|
  include_context 'workhorse headers'

  before do
    stub_feature_flags(debian_packages: true, debian_group_packages: true)
  end

  let_it_be(:private_container, freeze: can_freeze) { create(container_type, :private) }
  let_it_be(:public_container, freeze: can_freeze) { create(container_type, :public) }
  let_it_be(:user, freeze: true) { create(:user) }
  let_it_be(:personal_access_token, freeze: true) { create(:personal_access_token, user: user) }

  let_it_be(:private_distribution, freeze: true) { create("debian_#{container_type}_distribution", :with_file, container: private_container, codename: 'existing-codename') }
  let_it_be(:private_distribution_key, freeze: true) { create("debian_#{container_type}_distribution_key", distribution: private_distribution) }
  let_it_be(:private_component, freeze: true) { create("debian_#{container_type}_component", distribution: private_distribution, name: 'existing-component') }
  let_it_be(:private_architecture_all, freeze: true) { create("debian_#{container_type}_architecture", distribution: private_distribution, name: 'all') }
  let_it_be(:private_architecture, freeze: true) { create("debian_#{container_type}_architecture", distribution: private_distribution, name: 'existing-arch') }
  let_it_be(:private_component_file) { create("debian_#{container_type}_component_file", component: private_component, architecture: private_architecture) }
  let_it_be(:private_component_file_sources) { create("debian_#{container_type}_component_file", :sources, component: private_component) }
  let_it_be(:private_component_file_di) { create("debian_#{container_type}_component_file", :di_packages, component: private_component, architecture: private_architecture) }
  let_it_be(:private_component_file_older_sha256) { create("debian_#{container_type}_component_file", :older_sha256, component: private_component, architecture: private_architecture) }
  let_it_be(:private_component_file_sources_older_sha256) { create("debian_#{container_type}_component_file", :sources, :older_sha256, component: private_component) }
  let_it_be(:private_component_file_di_older_sha256) { create("debian_#{container_type}_component_file", :di_packages, :older_sha256, component: private_component, architecture: private_architecture) }

  let_it_be(:public_distribution, freeze: true) { create("debian_#{container_type}_distribution", :with_file, container: public_container, codename: 'existing-codename') }
  let_it_be(:public_distribution_key, freeze: true) { create("debian_#{container_type}_distribution_key", distribution: public_distribution) }
  let_it_be(:public_component, freeze: true) { create("debian_#{container_type}_component", distribution: public_distribution, name: 'existing-component') }
  let_it_be(:public_architecture_all, freeze: true) { create("debian_#{container_type}_architecture", distribution: public_distribution, name: 'all') }
  let_it_be(:public_architecture, freeze: true) { create("debian_#{container_type}_architecture", distribution: public_distribution, name: 'existing-arch') }
  let_it_be(:public_component_file) { create("debian_#{container_type}_component_file", component: public_component, architecture: public_architecture) }
  let_it_be(:public_component_file_sources) { create("debian_#{container_type}_component_file", :sources, component: public_component) }
  let_it_be(:public_component_file_di) { create("debian_#{container_type}_component_file", :di_packages, component: public_component, architecture: public_architecture) }
  let_it_be(:public_component_file_older_sha256) { create("debian_#{container_type}_component_file", :older_sha256, component: public_component, architecture: public_architecture) }
  let_it_be(:public_component_file_sources_older_sha256) { create("debian_#{container_type}_component_file", :sources, :older_sha256, component: public_component) }
  let_it_be(:public_component_file_di_older_sha256) { create("debian_#{container_type}_component_file", :di_packages, :older_sha256, component: public_component, architecture: public_architecture) }

  if container_type == :group
    let_it_be(:private_project) { create(:project, :private, group: private_container) }
    let_it_be(:public_project) { create(:project, :public, group: public_container) }
    let_it_be(:private_project_distribution) { create(:debian_project_distribution, container: private_project, codename: 'existing-codename') }
    let_it_be(:public_project_distribution) { create(:debian_project_distribution, container: public_project, codename: 'existing-codename') }

    let(:project) { { private: private_project, public: public_project }[visibility_level] }
  else
    let_it_be(:private_project) { private_container }
    let_it_be(:public_project) { public_container }
    let_it_be(:private_project_distribution) { private_distribution }
    let_it_be(:public_project_distribution) { public_distribution }
  end

  let_it_be(:private_package) { create(:debian_package, project: private_project, published_in: private_project_distribution, with_changes_file: true) }
  let_it_be(:public_package) { create(:debian_package, project: public_project, published_in: public_project_distribution, with_changes_file: true) }

  let(:visibility_level) { :public }

  let(:distribution) { { private: private_distribution, public: public_distribution }[visibility_level] }
  let(:architecture) { { private: private_architecture, public: public_architecture }[visibility_level] }
  let(:component) { { private: private_component, public: public_component }[visibility_level] }
  let(:component_file) { { private: private_component_file, public: public_component_file }[visibility_level] }
  let(:component_file_sources) { { private: private_component_file_sources, public: public_component_file_sources }[visibility_level] }
  let(:component_file_di) { { private: private_component_file_di, public: public_component_file_di }[visibility_level] }
  let(:component_file_older_sha256) { { private: private_component_file_older_sha256, public: public_component_file_older_sha256 }[visibility_level] }
  let(:component_file_sources_older_sha256) { { private: private_component_file_sources_older_sha256, public: public_component_file_sources_older_sha256 }[visibility_level] }
  let(:component_file_di_older_sha256) { { private: private_component_file_di_older_sha256, public: public_component_file_di_older_sha256 }[visibility_level] }
  let(:package) { { private: private_package, public: public_package }[visibility_level] }
  let(:letter) { package.name[0..2] == 'lib' ? package.name[0..3] : package.name[0] }

  let(:method) { :get }

  let(:workhorse_params) do
    if method == :put
      file_upload = fixture_file_upload("spec/fixtures/packages/debian/#{file_name}")
      { file: file_upload }
    else
      {}
    end
  end

  let(:extra_params) { {} }
  let(:api_params) { workhorse_params.merge(extra_params) }

  let(:auth_headers) { {} }
  let(:wh_headers) do
    if method == :put
      workhorse_headers
    else
      {}
    end
  end

  let(:headers) { auth_headers.merge(wh_headers) }

  let(:send_rewritten_field) { true }

  subject do
    if method == :put
      workhorse_finalize(
        api(url),
        method: method,
        file_key: :file,
        params: api_params,
        headers: headers,
        send_rewritten_field: send_rewritten_field
      )
    else
      send method, api(url), headers: headers, params: api_params
    end
  end
end

RSpec.shared_context 'Debian repository auth headers' do |user_type, auth_method = :private_token|
  let(:token) { user_type == :invalid_token ? 'wrong' : personal_access_token.token }

  let(:auth_headers) do
    if user_type == :anonymous
      {}
    elsif auth_method == :private_token
      { 'Private-Token' => token }
    else
      basic_auth_header(user.username, token)
    end
  end
end

RSpec.shared_context 'Debian repository access' do |visibility_level, user_type, auth_method|
  include_context 'Debian repository auth headers', user_type, auth_method do
    let(:containers) { { private: private_container, public: public_container } }
    let(:container) { containers[visibility_level] }

    before do
      container.send("add_#{user_type}", user) if user_type != :anonymous && user_type != :not_a_member && user_type != :invalid_token
    end
  end
end
