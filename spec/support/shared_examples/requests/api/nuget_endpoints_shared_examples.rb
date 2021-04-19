# frozen_string_literal: true

RSpec.shared_examples 'handling nuget service requests' do |anonymous_requests_example_name: 'process nuget service index request', anonymous_requests_status: :success|
  subject { get api(url) }

  context 'with valid target' do
    using RSpec::Parameterized::TableSyntax

    context 'personal token' do
      where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
        'PUBLIC'  | :developer  | true  | true  | 'process nuget service index request' | :success
        'PUBLIC'  | :guest      | true  | true  | 'process nuget service index request' | :success
        'PUBLIC'  | :developer  | true  | false | 'rejects nuget packages access'       | :unauthorized
        'PUBLIC'  | :guest      | true  | false | 'rejects nuget packages access'       | :unauthorized
        'PUBLIC'  | :developer  | false | true  | 'process nuget service index request' | :success
        'PUBLIC'  | :guest      | false | true  | 'process nuget service index request' | :success
        'PUBLIC'  | :developer  | false | false | 'rejects nuget packages access'       | :unauthorized
        'PUBLIC'  | :guest      | false | false | 'rejects nuget packages access'       | :unauthorized
        'PUBLIC'  | :anonymous  | false | true  | anonymous_requests_example_name       | anonymous_requests_status
        'PRIVATE' | :developer  | true  | true  | 'process nuget service index request' | :success
        'PRIVATE' | :guest      | true  | true  | 'rejects nuget packages access'       | :forbidden
        'PRIVATE' | :developer  | true  | false | 'rejects nuget packages access'       | :unauthorized
        'PRIVATE' | :guest      | true  | false | 'rejects nuget packages access'       | :unauthorized
        'PRIVATE' | :developer  | false | true  | 'rejects nuget packages access'       | :not_found
        'PRIVATE' | :guest      | false | true  | 'rejects nuget packages access'       | :not_found
        'PRIVATE' | :developer  | false | false | 'rejects nuget packages access'       | :unauthorized
        'PRIVATE' | :guest      | false | false | 'rejects nuget packages access'       | :unauthorized
        'PRIVATE' | :anonymous  | false | true  | 'rejects nuget packages access'       | :unauthorized
      end

      with_them do
        let(:token) { user_token ? personal_access_token.token : 'wrong' }
        let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }

        subject { get api(url), headers: headers }

        before do
          update_visibility_to(Gitlab::VisibilityLevel.const_get(visibility_level, false))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end

    context 'with job token' do
      where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
        'PUBLIC'  | :developer  | true  | true  | 'process nuget service index request' | :success
        'PUBLIC'  | :guest      | true  | true  | 'process nuget service index request' | :success
        'PUBLIC'  | :developer  | true  | false | 'rejects nuget packages access'       | :unauthorized
        'PUBLIC'  | :guest      | true  | false | 'rejects nuget packages access'       | :unauthorized
        'PUBLIC'  | :developer  | false | true  | 'process nuget service index request' | :success
        'PUBLIC'  | :guest      | false | true  | 'process nuget service index request' | :success
        'PUBLIC'  | :developer  | false | false | 'rejects nuget packages access'       | :unauthorized
        'PUBLIC'  | :guest      | false | false | 'rejects nuget packages access'       | :unauthorized
        'PUBLIC'  | :anonymous  | false | true  | anonymous_requests_example_name       | anonymous_requests_status
        'PRIVATE' | :developer  | true  | true  | 'process nuget service index request' | :success
        'PRIVATE' | :guest      | true  | true  | 'rejects nuget packages access'       | :forbidden
        'PRIVATE' | :developer  | true  | false | 'rejects nuget packages access'       | :unauthorized
        'PRIVATE' | :guest      | true  | false | 'rejects nuget packages access'       | :unauthorized
        'PRIVATE' | :developer  | false | true  | 'rejects nuget packages access'       | :not_found
        'PRIVATE' | :guest      | false | true  | 'rejects nuget packages access'       | :not_found
        'PRIVATE' | :developer  | false | false | 'rejects nuget packages access'       | :unauthorized
        'PRIVATE' | :guest      | false | false | 'rejects nuget packages access'       | :unauthorized
        'PRIVATE' | :anonymous  | false | true  | 'rejects nuget packages access'       | :unauthorized
      end

      with_them do
        let(:job) { user_token ? create(:ci_build, project: project, user: user, status: :running) : double(token: 'wrong') }
        let(:headers) { user_role == :anonymous ? {} : job_basic_auth_header(job) }

        subject { get api(url), headers: headers }

        before do
          update_visibility_to(Gitlab::VisibilityLevel.const_get(visibility_level, false))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end
  end

  it_behaves_like 'deploy token for package GET requests' do
    before do
      update_visibility_to(Gitlab::VisibilityLevel::PRIVATE)
    end
  end

  it_behaves_like 'rejects nuget access with unknown target id'

  it_behaves_like 'rejects nuget access with invalid target id'
end

RSpec.shared_examples 'handling nuget metadata requests with package name' do |anonymous_requests_example_name: 'process nuget metadata request at package name level', anonymous_requests_status: :success|
  include_context 'with expected presenters dependency groups'

  let_it_be(:package_name) { 'Dummy.Package' }
  let_it_be(:packages) { create_list(:nuget_package, 5, :with_metadatum, name: package_name, project: project) }
  let_it_be(:tags) { packages.each { |pkg| create(:packages_tag, package: pkg, name: 'test') } }

  subject { get api(url) }

  before do
    packages.each { |pkg| create_dependencies_for(pkg) }
  end

  context 'with valid target' do
    using RSpec::Parameterized::TableSyntax

    where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
      'PUBLIC'  | :developer  | true  | true  | 'process nuget metadata request at package name level' | :success
      'PUBLIC'  | :guest      | true  | true  | 'process nuget metadata request at package name level' | :success
      'PUBLIC'  | :developer  | true  | false | 'rejects nuget packages access'                        | :unauthorized
      'PUBLIC'  | :guest      | true  | false | 'rejects nuget packages access'                        | :unauthorized
      'PUBLIC'  | :developer  | false | true  | 'process nuget metadata request at package name level' | :success
      'PUBLIC'  | :guest      | false | true  | 'process nuget metadata request at package name level' | :success
      'PUBLIC'  | :developer  | false | false | 'rejects nuget packages access'                        | :unauthorized
      'PUBLIC'  | :guest      | false | false | 'rejects nuget packages access'                        | :unauthorized
      'PUBLIC'  | :anonymous  | false | true  | anonymous_requests_example_name                        | anonymous_requests_status
      'PRIVATE' | :developer  | true  | true  | 'process nuget metadata request at package name level' | :success
      'PRIVATE' | :guest      | true  | true  | 'rejects nuget packages access'                        | :forbidden
      'PRIVATE' | :developer  | true  | false | 'rejects nuget packages access'                        | :unauthorized
      'PRIVATE' | :guest      | true  | false | 'rejects nuget packages access'                        | :unauthorized
      'PRIVATE' | :developer  | false | true  | 'rejects nuget packages access'                        | :not_found
      'PRIVATE' | :guest      | false | true  | 'rejects nuget packages access'                        | :not_found
      'PRIVATE' | :developer  | false | false | 'rejects nuget packages access'                        | :unauthorized
      'PRIVATE' | :guest      | false | false | 'rejects nuget packages access'                        | :unauthorized
      'PRIVATE' | :anonymous  | false | true  | 'rejects nuget packages access'                        | :unauthorized
    end

    with_them do
      let(:token) { user_token ? personal_access_token.token : 'wrong' }
      let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }

      subject { get api(url), headers: headers }

      before do
        update_visibility_to(Gitlab::VisibilityLevel.const_get(visibility_level, false))
      end

      it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
    end

    it_behaves_like 'deploy token for package GET requests' do
      before do
        update_visibility_to(Gitlab::VisibilityLevel::PRIVATE)
      end
    end

    it_behaves_like 'rejects nuget access with unknown target id'

    it_behaves_like 'rejects nuget access with invalid target id'
  end
end

RSpec.shared_examples 'handling nuget metadata requests with package name and package version' do |anonymous_requests_example_name: 'process nuget metadata request at package name and package version level', anonymous_requests_status: :success|
  include_context 'with expected presenters dependency groups'

  let_it_be(:package_name) { 'Dummy.Package' }
  let_it_be(:package) { create(:nuget_package, :with_metadatum, name: package_name, project: project) }
  let_it_be(:tag) { create(:packages_tag, package: package, name: 'test') }

  subject { get api(url) }

  before do
    create_dependencies_for(package)
  end

  context 'with valid target' do
    using RSpec::Parameterized::TableSyntax

    where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
      'PUBLIC'  | :developer  | true  | true  | 'process nuget metadata request at package name and package version level' | :success
      'PUBLIC'  | :guest      | true  | true  | 'process nuget metadata request at package name and package version level' | :success
      'PUBLIC'  | :developer  | true  | false | 'rejects nuget packages access'                                            | :unauthorized
      'PUBLIC'  | :guest      | true  | false | 'rejects nuget packages access'                                            | :unauthorized
      'PUBLIC'  | :developer  | false | true  | 'process nuget metadata request at package name and package version level' | :success
      'PUBLIC'  | :guest      | false | true  | 'process nuget metadata request at package name and package version level' | :success
      'PUBLIC'  | :developer  | false | false | 'rejects nuget packages access'                                            | :unauthorized
      'PUBLIC'  | :guest      | false | false | 'rejects nuget packages access'                                            | :unauthorized
      'PUBLIC'  | :anonymous  | false | true  | anonymous_requests_example_name                                            | anonymous_requests_status
      'PRIVATE' | :developer  | true  | true  | 'process nuget metadata request at package name and package version level' | :success
      'PRIVATE' | :guest      | true  | true  | 'rejects nuget packages access'                                            | :forbidden
      'PRIVATE' | :developer  | true  | false | 'rejects nuget packages access'                                            | :unauthorized
      'PRIVATE' | :guest      | true  | false | 'rejects nuget packages access'                                            | :unauthorized
      'PRIVATE' | :developer  | false | true  | 'rejects nuget packages access'                                            | :not_found
      'PRIVATE' | :guest      | false | true  | 'rejects nuget packages access'                                            | :not_found
      'PRIVATE' | :developer  | false | false | 'rejects nuget packages access'                                            | :unauthorized
      'PRIVATE' | :guest      | false | false | 'rejects nuget packages access'                                            | :unauthorized
      'PRIVATE' | :anonymous  | false | true  | 'rejects nuget packages access'                                            | :unauthorized
    end

    with_them do
      let(:token) { user_token ? personal_access_token.token : 'wrong' }
      let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }

      subject { get api(url), headers: headers }

      before do
        update_visibility_to(Gitlab::VisibilityLevel.const_get(visibility_level, false))
      end

      it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
    end
  end

  it_behaves_like 'deploy token for package GET requests' do
    before do
      update_visibility_to(Gitlab::VisibilityLevel::PRIVATE)
    end
  end

  it_behaves_like 'rejects nuget access with unknown target id'

  it_behaves_like 'rejects nuget access with invalid target id'
end

RSpec.shared_examples 'handling nuget search requests' do |anonymous_requests_example_name: 'process nuget search request', anonymous_requests_status: :success|
  let_it_be(:package_a) { create(:nuget_package, :with_metadatum, name: 'Dummy.PackageA', project: project) }
  let_it_be(:tag) { create(:packages_tag, package: package_a, name: 'test') }
  let_it_be(:packages_b) { create_list(:nuget_package, 5, name: 'Dummy.PackageB', project: project) }
  let_it_be(:packages_c) { create_list(:nuget_package, 5, name: 'Dummy.PackageC', project: project) }
  let_it_be(:package_d) { create(:nuget_package, name: 'Dummy.PackageD', version: '5.0.5-alpha', project: project) }
  let_it_be(:package_e) { create(:nuget_package, name: 'Foo.BarE', project: project) }
  let(:search_term) { 'uMmy' }
  let(:take) { 26 }
  let(:skip) { 0 }
  let(:include_prereleases) { true }
  let(:query_parameters) { { q: search_term, take: take, skip: skip, prerelease: include_prereleases }.compact }

  subject { get api(url) }

  context 'with valid target' do
    using RSpec::Parameterized::TableSyntax

    where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
      'PUBLIC'  | :developer  | true  | true  | 'process nuget search request'  | :success
      'PUBLIC'  | :guest      | true  | true  | 'process nuget search request'  | :success
      'PUBLIC'  | :developer  | true  | false | 'rejects nuget packages access' | :unauthorized
      'PUBLIC'  | :guest      | true  | false | 'rejects nuget packages access' | :unauthorized
      'PUBLIC'  | :developer  | false | true  | 'process nuget search request'  | :success
      'PUBLIC'  | :guest      | false | true  | 'process nuget search request'  | :success
      'PUBLIC'  | :developer  | false | false | 'rejects nuget packages access' | :unauthorized
      'PUBLIC'  | :guest      | false | false | 'rejects nuget packages access' | :unauthorized
      'PUBLIC'  | :anonymous  | false | true  | anonymous_requests_example_name | anonymous_requests_status
      'PRIVATE' | :developer  | true  | true  | 'process nuget search request'  | :success
      'PRIVATE' | :guest      | true  | true  | 'rejects nuget packages access' | :forbidden
      'PRIVATE' | :developer  | true  | false | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :guest      | true  | false | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :developer  | false | true  | 'rejects nuget packages access' | :not_found
      'PRIVATE' | :guest      | false | true  | 'rejects nuget packages access' | :not_found
      'PRIVATE' | :developer  | false | false | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :guest      | false | false | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :anonymous  | false | true  | 'rejects nuget packages access' | :unauthorized
    end

    with_them do
      let(:token) { user_token ? personal_access_token.token : 'wrong' }
      let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }

      subject { get api(url), headers: headers }

      before do
        update_visibility_to(Gitlab::VisibilityLevel.const_get(visibility_level, false))
      end

      it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
    end
  end

  it_behaves_like 'deploy token for package GET requests' do
    before do
      update_visibility_to(Gitlab::VisibilityLevel::PRIVATE)
    end
  end

  it_behaves_like 'rejects nuget access with unknown target id'

  it_behaves_like 'rejects nuget access with invalid target id'
end
