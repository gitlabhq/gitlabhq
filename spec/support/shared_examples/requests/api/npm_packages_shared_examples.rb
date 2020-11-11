# frozen_string_literal: true

RSpec.shared_examples 'handling get metadata requests' do
  let_it_be(:package_dependency_link1) { create(:packages_dependency_link, package: package, dependency_type: :dependencies) }
  let_it_be(:package_dependency_link2) { create(:packages_dependency_link, package: package, dependency_type: :devDependencies) }
  let_it_be(:package_dependency_link3) { create(:packages_dependency_link, package: package, dependency_type: :bundleDependencies) }
  let_it_be(:package_dependency_link4) { create(:packages_dependency_link, package: package, dependency_type: :peerDependencies) }

  let(:params) { {} }
  let(:headers) { {} }

  subject { get(url, params: params, headers: headers) }

  shared_examples 'returning the npm package info' do
    it 'returns the package info' do
      subject

      expect_a_valid_package_response
    end
  end

  shared_examples 'a package that requires auth' do
    it 'denies request without oauth token' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'with oauth token' do
      let(:params) { { access_token: token.token } }

      it 'returns the package info with oauth token' do
        subject

        expect_a_valid_package_response
      end
    end

    context 'with job token' do
      let(:params) { { job_token: job.token } }

      it 'returns the package info with running job token' do
        subject

        expect_a_valid_package_response
      end

      it 'denies request without running job token' do
        job.update!(status: :success)

        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with deploy token' do
      let(:headers) { build_token_auth_header(deploy_token.token) }

      it 'returns the package info with deploy token' do
        subject

        expect_a_valid_package_response
      end
    end
  end

  context 'a public project' do
    it_behaves_like 'returning the npm package info'

    context 'project path with a dot' do
      before do
        project.update!(path: 'foo.bar')
      end

      it_behaves_like 'returning the npm package info'
    end

    context 'with request forward disabled' do
      before do
        stub_application_setting(npm_package_requests_forwarding: false)
      end

      it_behaves_like 'returning the npm package info'

      context 'with unknown package' do
        let(:package_name) { 'unknown' }

        it 'returns the proper response' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with request forward enabled' do
      before do
        stub_application_setting(npm_package_requests_forwarding: true)
      end

      it_behaves_like 'returning the npm package info'

      context 'with unknown package' do
        let(:package_name) { 'unknown' }

        it 'returns a redirect' do
          subject

          expect(response).to have_gitlab_http_status(:found)
          expect(response.headers['Location']).to eq('https://registry.npmjs.org/unknown')
        end

        it_behaves_like 'a gitlab tracking event', described_class.name, 'npm_request_forward'
      end
    end
  end

  context 'internal project' do
    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
    end

    it_behaves_like 'a package that requires auth'
  end

  context 'private project' do
    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    end

    it_behaves_like 'a package that requires auth'

    context 'with guest' do
      let(:params) { { access_token: token.token } }

      it 'denies request when not enough permissions' do
        project.add_guest(user)

        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  def expect_a_valid_package_response
    expect(response).to have_gitlab_http_status(:ok)
    expect(response.media_type).to eq('application/json')
    expect(response).to match_response_schema('public_api/v4/packages/npm_package')
    expect(json_response['name']).to eq(package.name)
    expect(json_response['versions'][package.version]).to match_schema('public_api/v4/packages/npm_package_version')
    ::Packages::Npm::PackagePresenter::NPM_VALID_DEPENDENCY_TYPES.each do |dependency_type|
      expect(json_response.dig('versions', package.version, dependency_type.to_s)).to be_any
    end
    expect(json_response['dist-tags']).to match_schema('public_api/v4/packages/npm_package_tags')
  end
end

RSpec.shared_examples 'handling get dist tags requests' do
  let_it_be(:package_tag1) { create(:packages_tag, package: package) }
  let_it_be(:package_tag2) { create(:packages_tag, package: package) }

  let(:params) { {} }

  subject { get(url, params: params) }

  context 'with public project' do
    context 'with authenticated user' do
      let(:params) { { private_token: personal_access_token.token } }

      it_behaves_like 'returns package tags', :maintainer
      it_behaves_like 'returns package tags', :developer
      it_behaves_like 'returns package tags', :reporter
      it_behaves_like 'returns package tags', :guest
    end

    context 'with unauthenticated user' do
      it_behaves_like 'returns package tags', :no_type
    end
  end

  context 'with private project' do
    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    end

    context 'with authenticated user' do
      let(:params) { { private_token: personal_access_token.token } }

      it_behaves_like 'returns package tags', :maintainer
      it_behaves_like 'returns package tags', :developer
      it_behaves_like 'returns package tags', :reporter
      it_behaves_like 'rejects package tags access', :guest, :forbidden
    end

    context 'with unauthenticated user' do
      it_behaves_like 'rejects package tags access', :no_type, :not_found
    end
  end
end

RSpec.shared_examples 'handling create dist tag requests' do
  let_it_be(:tag_name) { 'test' }

  let(:params) { {} }
  let(:env) { {} }
  let(:version) { package.version }

  subject { put(url, env: env, params: params) }

  context 'with public project' do
    context 'with authenticated user' do
      let(:params) { { private_token: personal_access_token.token } }
      let(:env) { { 'api.request.body': version } }

      it_behaves_like 'create package tag', :maintainer
      it_behaves_like 'create package tag', :developer
      it_behaves_like 'rejects package tags access', :reporter, :forbidden
      it_behaves_like 'rejects package tags access', :guest, :forbidden
    end

    context 'with unauthenticated user' do
      it_behaves_like 'rejects package tags access', :no_type, :unauthorized
    end
  end
end

RSpec.shared_examples 'handling delete dist tag requests' do
  let_it_be(:package_tag) { create(:packages_tag, package: package) }

  let(:params) { {} }
  let(:tag_name) { package_tag.name }

  subject { delete(url, params: params) }

  context 'with public project' do
    context 'with authenticated user' do
      let(:params) { { private_token: personal_access_token.token } }

      it_behaves_like 'delete package tag', :maintainer
      it_behaves_like 'rejects package tags access', :developer, :forbidden
      it_behaves_like 'rejects package tags access', :reporter, :forbidden
      it_behaves_like 'rejects package tags access', :guest, :forbidden
    end

    context 'with unauthenticated user' do
      it_behaves_like 'rejects package tags access', :no_type, :unauthorized
    end
  end

  context 'with private project' do
    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    end

    context 'with authenticated user' do
      let(:params) { { private_token: personal_access_token.token } }

      it_behaves_like 'delete package tag', :maintainer
      it_behaves_like 'rejects package tags access', :developer, :forbidden
      it_behaves_like 'rejects package tags access', :reporter, :forbidden
      it_behaves_like 'rejects package tags access', :guest, :forbidden
    end

    context 'with unauthenticated user' do
      it_behaves_like 'rejects package tags access', :no_type, :unauthorized
    end
  end
end
