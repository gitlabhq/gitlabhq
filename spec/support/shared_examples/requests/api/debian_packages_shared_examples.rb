# frozen_string_literal: true

RSpec.shared_context 'Debian repository shared context' do |object_type|
  before do
    stub_feature_flags(debian_packages: true)
  end

  if object_type == :project
    let(:project) { create(:project, :public) }
  elsif object_type == :group
    let(:group) { create(:group, :public) }
  end

  let(:user) { create(:user) }
  let(:personal_access_token) { create(:personal_access_token, user: user) }

  let(:distribution) { 'bullseye' }
  let(:component) { 'main' }
  let(:architecture) { 'amd64' }
  let(:source_package) { 'sample' }
  let(:letter) { source_package[0..2] == 'lib' ? source_package[0..3] : source_package[0] }
  let(:package_name) { 'libsample0' }
  let(:package_version) { '1.2.3~alpha2' }
  let(:file_name) { "#{package_name}_#{package_version}_#{architecture}.deb" }

  let(:method) { :get }

  let(:workhorse_params) do
    if method == :put
      file_upload = fixture_file_upload("spec/fixtures/packages/debian/#{file_name}")
      { file: file_upload }
    else
      {}
    end
  end

  let(:params) { workhorse_params }

  let(:auth_headers) { {} }
  let(:workhorse_headers) do
    if method == :put
      workhorse_token = JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256')
      { 'GitLab-Workhorse' => '1.0', Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => workhorse_token }
    else
      {}
    end
  end

  let(:headers) { auth_headers.merge(workhorse_headers) }

  let(:send_rewritten_field) { true }

  subject do
    if method == :put
      workhorse_finalize(
        api(url),
        method: method,
        file_key: :file,
        params: params,
        headers: headers,
        send_rewritten_field: send_rewritten_field
      )
    else
      send method, api(url), headers: headers, params: params
    end
  end
end

RSpec.shared_context 'Debian repository auth headers' do |user_role, user_token, auth_method = :token|
  let(:token) { user_token ? personal_access_token.token : 'wrong' }

  let(:auth_headers) do
    if user_role == :anonymous
      {}
    elsif auth_method == :token
      { 'Private-Token' => token }
    else
      basic_auth_header(user.username, token)
    end
  end
end

RSpec.shared_context 'Debian repository project access' do |project_visibility_level, user_role, user_token, auth_method|
  include_context 'Debian repository auth headers', user_role, user_token, auth_method do
    before do
      project.update_column(:visibility_level, Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
    end
  end
end

RSpec.shared_examples 'Debian project repository GET request' do |user_role, add_member, status, body|
  context "for user type #{user_role}" do
    before do
      project.send("add_#{user_role}", user) if add_member && user_role != :anonymous
    end

    and_body = body.nil? ? '' : ' and expected body'

    it "returns #{status}#{and_body}" do
      subject

      expect(response).to have_gitlab_http_status(status)

      unless body.nil?
        expect(response.body).to eq(body)
      end
    end
  end
end

RSpec.shared_examples 'Debian project repository PUT request' do |user_role, add_member, status, body|
  context "for user type #{user_role}" do
    before do
      project.send("add_#{user_role}", user) if add_member && user_role != :anonymous
    end

    and_body = body.nil? ? '' : ' and expected body'

    if status == :created
      it 'creates package files' do
        pending "Debian package creation not implemented"
        expect { subject }
            .to change { project.packages.debian.count }.by(1)

        expect(response).to have_gitlab_http_status(status)

        unless body.nil?
          expect(response.body).to eq(body)
        end
      end
      it_behaves_like 'a package tracking event', described_class.name, 'push_package'
    else
      it "returns #{status}#{and_body}" do
        subject

        expect(response).to have_gitlab_http_status(status)

        unless body.nil?
          expect(response.body).to eq(body)
        end
      end
    end
  end
end

RSpec.shared_examples 'rejects Debian access with unknown project id' do
  context 'with an unknown project' do
    let(:project) { double(id: non_existing_record_id) }

    context 'as anonymous' do
      it_behaves_like 'Debian project repository GET request', :anonymous, true, :not_found, nil
    end

    context 'as authenticated user' do
      subject { get api(url), headers: basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'Debian project repository GET request', :anonymous, true, :not_found, nil
    end
  end
end

RSpec.shared_examples 'Debian project repository GET endpoint' do |success_status, success_body|
  context 'with valid project' do
    using RSpec::Parameterized::TableSyntax

    where(:project_visibility_level, :user_role, :member, :user_token, :expected_status, :expected_body) do
      'PUBLIC'  | :developer  | true  | true  | success_status | success_body
      'PUBLIC'  | :guest      | true  | true  | success_status | success_body
      'PUBLIC'  | :developer  | true  | false | success_status | success_body
      'PUBLIC'  | :guest      | true  | false | success_status | success_body
      'PUBLIC'  | :developer  | false | true  | success_status | success_body
      'PUBLIC'  | :guest      | false | true  | success_status | success_body
      'PUBLIC'  | :developer  | false | false | success_status | success_body
      'PUBLIC'  | :guest      | false | false | success_status | success_body
      'PUBLIC'  | :anonymous  | false | true  | success_status | success_body
      'PRIVATE' | :developer  | true  | true  | success_status | success_body
      'PRIVATE' | :guest      | true  | true  | :forbidden     | nil
      'PRIVATE' | :developer  | true  | false | :not_found     | nil
      'PRIVATE' | :guest      | true  | false | :not_found     | nil
      'PRIVATE' | :developer  | false | true  | :not_found     | nil
      'PRIVATE' | :guest      | false | true  | :not_found     | nil
      'PRIVATE' | :developer  | false | false | :not_found     | nil
      'PRIVATE' | :guest      | false | false | :not_found     | nil
      'PRIVATE' | :anonymous  | false | true  | :not_found     | nil
    end

    with_them do
      include_context 'Debian repository project access', params[:project_visibility_level], params[:user_role], params[:user_token], :basic do
        it_behaves_like 'Debian project repository GET request', params[:user_role], params[:member], params[:expected_status], params[:expected_body]
      end
    end
  end

  it_behaves_like 'rejects Debian access with unknown project id'
end

RSpec.shared_examples 'Debian project repository PUT endpoint' do |success_status, success_body|
  context 'with valid project' do
    using RSpec::Parameterized::TableSyntax

    where(:project_visibility_level, :user_role, :member, :user_token, :expected_status, :expected_body) do
      'PUBLIC'  | :developer  | true  | true  | success_status | nil
      'PUBLIC'  | :guest      | true  | true  | :forbidden     | nil
      'PUBLIC'  | :developer  | true  | false | :unauthorized  | nil
      'PUBLIC'  | :guest      | true  | false | :unauthorized  | nil
      'PUBLIC'  | :developer  | false | true  | :forbidden     | nil
      'PUBLIC'  | :guest      | false | true  | :forbidden     | nil
      'PUBLIC'  | :developer  | false | false | :unauthorized  | nil
      'PUBLIC'  | :guest      | false | false | :unauthorized  | nil
      'PUBLIC'  | :anonymous  | false | true  | :unauthorized  | nil
      'PRIVATE' | :developer  | true  | true  | success_status | nil
      'PRIVATE' | :guest      | true  | true  | :forbidden     | nil
      'PRIVATE' | :developer  | true  | false | :not_found     | nil
      'PRIVATE' | :guest      | true  | false | :not_found     | nil
      'PRIVATE' | :developer  | false | true  | :not_found     | nil
      'PRIVATE' | :guest      | false | true  | :not_found     | nil
      'PRIVATE' | :developer  | false | false | :not_found     | nil
      'PRIVATE' | :guest      | false | false | :not_found     | nil
      'PRIVATE' | :anonymous  | false | true  | :not_found     | nil
    end

    with_them do
      include_context 'Debian repository project access', params[:project_visibility_level], params[:user_role], params[:user_token], :basic do
        it_behaves_like 'Debian project repository PUT request', params[:user_role], params[:member], params[:expected_status], params[:expected_body]
      end
    end
  end

  it_behaves_like 'rejects Debian access with unknown project id'
end

RSpec.shared_context 'Debian repository group access' do |group_visibility_level, user_role, user_token, auth_method|
  include_context 'Debian repository auth headers', user_role, user_token, auth_method do
    before do
      group.update_column(:visibility_level, Gitlab::VisibilityLevel.const_get(group_visibility_level, false))
    end
  end
end

RSpec.shared_examples 'Debian group repository GET request' do |user_role, add_member, status, body|
  context "for user type #{user_role}" do
    before do
      group.send("add_#{user_role}", user) if add_member && user_role != :anonymous
    end

    and_body = body.nil? ? '' : ' and expected body'

    it "returns #{status}#{and_body}" do
      subject

      expect(response).to have_gitlab_http_status(status)

      unless body.nil?
        expect(response.body).to eq(body)
      end
    end
  end
end

RSpec.shared_examples 'rejects Debian access with unknown group id' do
  context 'with an unknown group' do
    let(:group) { double(id: non_existing_record_id) }

    context 'as anonymous' do
      it_behaves_like 'Debian group repository GET request', :anonymous, true, :not_found, nil
    end

    context 'as authenticated user' do
      subject { get api(url), headers: basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'Debian group repository GET request', :anonymous, true, :not_found, nil
    end
  end
end

RSpec.shared_examples 'Debian group repository GET endpoint' do |success_status, success_body|
  context 'with valid group' do
    using RSpec::Parameterized::TableSyntax

    where(:group_visibility_level, :user_role, :member, :user_token, :expected_status, :expected_body) do
      'PUBLIC'  | :developer  | true  | true  | success_status | success_body
      'PUBLIC'  | :guest      | true  | true  | success_status | success_body
      'PUBLIC'  | :developer  | true  | false | success_status | success_body
      'PUBLIC'  | :guest      | true  | false | success_status | success_body
      'PUBLIC'  | :developer  | false | true  | success_status | success_body
      'PUBLIC'  | :guest      | false | true  | success_status | success_body
      'PUBLIC'  | :developer  | false | false | success_status | success_body
      'PUBLIC'  | :guest      | false | false | success_status | success_body
      'PUBLIC'  | :anonymous  | false | true  | success_status | success_body
      'PRIVATE' | :developer  | true  | true  | success_status | success_body
      'PRIVATE' | :guest      | true  | true  | :forbidden     | nil
      'PRIVATE' | :developer  | true  | false | :not_found     | nil
      'PRIVATE' | :guest      | true  | false | :not_found     | nil
      'PRIVATE' | :developer  | false | true  | :not_found     | nil
      'PRIVATE' | :guest      | false | true  | :not_found     | nil
      'PRIVATE' | :developer  | false | false | :not_found     | nil
      'PRIVATE' | :guest      | false | false | :not_found     | nil
      'PRIVATE' | :anonymous  | false | true  | :not_found     | nil
    end

    with_them do
      include_context 'Debian repository group access', params[:group_visibility_level], params[:user_role], params[:user_token], :basic do
        it_behaves_like 'Debian group repository GET request', params[:user_role], params[:member], params[:expected_status], params[:expected_body]
      end
    end
  end

  it_behaves_like 'rejects Debian access with unknown group id'
end
