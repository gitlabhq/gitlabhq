# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::NpmGroupPackages, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  include_context 'npm api setup'

  describe 'GET /api/v4/groups/:id/-/packages/npm/*package_name' do
    let(:url) { api("/groups/#{group.id}/-/packages/npm/#{package_name}") }

    it_behaves_like 'handling get metadata requests', scope: :group
    it_behaves_like 'rejects invalid package names' do
      subject { get(url) }
    end

    it_behaves_like 'handling get metadata requests for packages in multiple projects'

    context 'with mixed group and project visibilities' do
      subject { get(url, headers: headers) }

      where(:auth, :group_visibility, :project_visibility, :user_role, :expected_status) do
        nil                    | :public   | :public   | nil        | :ok
        nil                    | :public   | :internal | nil        | :unauthorized
        nil                    | :public   | :private  | nil        | :unauthorized
        nil                    | :internal | :internal | nil        | :unauthorized
        nil                    | :internal | :private  | nil        | :unauthorized
        nil                    | :private  | :private  | nil        | :unauthorized

        :oauth                 | :public   | :public   | :guest     | :ok
        :oauth                 | :public   | :internal | :guest     | :ok
        :oauth                 | :public   | :private  | :guest     | :ok
        :oauth                 | :internal | :internal | :guest     | :ok
        :oauth                 | :internal | :private  | :guest     | :ok
        :oauth                 | :private  | :private  | :guest     | :ok
        :oauth                 | :public   | :public   | :reporter  | :ok
        :oauth                 | :public   | :internal | :reporter  | :ok
        :oauth                 | :public   | :private  | :reporter  | :ok
        :oauth                 | :internal | :internal | :reporter  | :ok
        :oauth                 | :internal | :private  | :reporter  | :ok
        :oauth                 | :private  | :private  | :reporter  | :ok

        :personal_access_token | :public   | :public   | :guest     | :ok
        :personal_access_token | :public   | :internal | :guest     | :ok
        :personal_access_token | :public   | :private  | :guest     | :ok
        :personal_access_token | :internal | :internal | :guest     | :ok
        :personal_access_token | :internal | :private  | :guest     | :ok
        :personal_access_token | :private  | :private  | :guest     | :ok
        :personal_access_token | :public   | :public   | :reporter  | :ok
        :personal_access_token | :public   | :internal | :reporter  | :ok
        :personal_access_token | :public   | :private  | :reporter  | :ok
        :personal_access_token | :internal | :internal | :reporter  | :ok
        :personal_access_token | :internal | :private  | :reporter  | :ok
        :personal_access_token | :private  | :private  | :reporter  | :ok

        :job_token             | :public   | :public   | :developer | :ok
        :job_token             | :public   | :internal | :developer | :ok
        :job_token             | :public   | :private  | :developer | :ok
        :job_token             | :internal | :internal | :developer | :ok
        :job_token             | :internal | :private  | :developer | :ok
        :job_token             | :private  | :private  | :developer | :ok

        :deploy_token          | :public   | :public   | nil        | :ok
        :deploy_token          | :public   | :internal | nil        | :ok
        :deploy_token          | :public   | :private  | nil        | :ok
        :deploy_token          | :internal | :internal | nil        | :ok
        :deploy_token          | :internal | :private  | nil        | :ok
        :deploy_token          | :private  | :private  | nil        | :ok
      end

      with_them do
        let(:headers) do
          case auth
          when :oauth
            build_token_auth_header(token.plaintext_token)
          when :personal_access_token
            build_token_auth_header(personal_access_token.token)
          when :job_token
            build_token_auth_header(job.token)
          when :deploy_token
            build_token_auth_header(deploy_token.token)
          else
            {}
          end
        end

        before do
          project.update!(visibility: project_visibility.to_s)
          project.send("add_#{user_role}", user) if user_role
          group.update!(visibility: group_visibility.to_s)
          group.send("add_#{user_role}", user) if user_role
        end

        it_behaves_like 'returning response status', params[:expected_status]
      end
    end

    context 'when user is a reporter of project but is not a direct member of group' do
      subject { get(url, headers: headers) }

      where(:group_visibility, :project_visibility, :expected_status) do
        :public   | :public   | :ok
        :public   | :internal | :ok
        :public   | :private  | :ok
        :internal | :internal | :ok
        :internal | :private  | :ok
        :private  | :private  | :ok
      end

      with_them do
        let(:headers) { build_token_auth_header(personal_access_token.token) }

        before do
          project.update!(visibility: project_visibility.to_s)
          project.add_reporter(user)

          group.update!(visibility: group_visibility.to_s)
        end

        it_behaves_like 'returning response status', params[:expected_status]
      end
    end

    context 'when metadata cache exists' do
      let_it_be(:npm_metadata_cache) { create(:npm_metadata_cache, package_name: package.name, project_id: project.id) }

      subject { get(url) }

      it_behaves_like 'generates metadata response "on-the-fly"'
    end
  end

  describe 'GET /api/v4/groups/:id/-/packages/npm/-/package/*package_name/dist-tags' do
    it_behaves_like 'handling get dist tags requests', scope: :group do
      let(:url) { api("/groups/#{group.id}/-/packages/npm/-/package/#{package_name}/dist-tags") }
    end
  end

  describe 'PUT /api/v4/groups/:id/-/packages/npm/-/package/*package_name/dist-tags/:tag' do
    it_behaves_like 'handling create dist tag requests', scope: :group do
      let(:url) { api("/groups/#{group.id}/-/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
    end

    it_behaves_like 'enqueue a worker to sync a metadata cache' do
      let(:tag_name) { 'test' }
      let(:url) { api("/groups/#{group.id}/-/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
      let(:env) { { 'api.request.body': package.version } }
      let(:headers) { build_token_auth_header(personal_access_token.token) }

      subject { put(url, env: env, headers: headers) }
    end
  end

  describe 'DELETE /api/v4/groups/:id/-/packages/npm/-/package/*package_name/dist-tags/:tag' do
    it_behaves_like 'handling delete dist tag requests', scope: :group do
      let(:url) { api("/groups/#{group.id}/-/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
    end

    it_behaves_like 'enqueue a worker to sync a metadata cache' do
      let_it_be(:package_tag) { create(:packages_tag, package: package) }

      let(:tag_name) { package_tag.name }
      let(:url) { api("/groups/#{group.id}/-/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
      let(:headers) { build_token_auth_header(personal_access_token.token) }

      subject { delete(url, headers: headers) }
    end
  end

  describe 'POST /api/v4/groups/:id/-/packages/npm/-/npm/v1/security/advisories/bulk' do
    it_behaves_like 'handling audit request', path: 'advisories/bulk', scope: :group do
      let(:url) { api("/groups/#{group.id}/-/packages/npm/-/npm/v1/security/advisories/bulk") }
    end
  end

  describe 'POST /api/v4/groups/:id/-/packages/npm/-/npm/v1/security/audits/quick' do
    it_behaves_like 'handling audit request', path: 'audits/quick', scope: :group do
      let(:url) { api("/groups/#{group.id}/-/packages/npm/-/npm/v1/security/audits/quick") }
    end
  end
end
