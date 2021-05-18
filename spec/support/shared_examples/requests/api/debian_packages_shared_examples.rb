# frozen_string_literal: true

RSpec.shared_context 'Debian repository shared context' do |container_type, can_freeze|
  include_context 'workhorse headers'

  before do
    stub_feature_flags(debian_packages: true)
  end

  let_it_be(:private_container, freeze: can_freeze) { create(container_type, :private) }
  let_it_be(:public_container, freeze: can_freeze) { create(container_type, :public) }
  let_it_be(:user, freeze: true) { create(:user) }
  let_it_be(:personal_access_token, freeze: true) { create(:personal_access_token, user: user) }

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

  let(:api_params) { workhorse_params }

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

RSpec.shared_context 'Debian repository access' do |visibility_level, user_role, add_member, user_token, auth_method|
  include_context 'Debian repository auth headers', user_role, user_token, auth_method do
    let(:containers) { { private: private_container, public: public_container } }
    let(:container) { containers[visibility_level] }

    before do
      container.send("add_#{user_role}", user) if add_member && user_role != :anonymous
    end
  end
end

RSpec.shared_examples 'Debian repository GET request' do |status, body = nil|
  and_body = body.nil? ? '' : ' and expected body'

  it "returns #{status}#{and_body}" do
    subject

    expect(response).to have_gitlab_http_status(status)

    unless body.nil?
      expect(response.body).to eq(body)
    end
  end
end

RSpec.shared_examples 'Debian repository upload request' do |status, body = nil|
  and_body = body.nil? ? '' : ' and expected body'

  if status == :created
    it 'creates package files', :aggregate_failures do
      pending "Debian package creation not implemented"

      expect { subject }
          .to change { container.packages.debian.count }.by(1)

      expect(response).to have_gitlab_http_status(status)
      expect(response.media_type).to eq('text/plain')

      unless body.nil?
        expect(response.body).to eq(body)
      end
    end
    it_behaves_like 'a package tracking event', described_class.name, 'push_package'
  else
    it "returns #{status}#{and_body}", :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(status)

      unless body.nil?
        expect(response.body).to eq(body)
      end
    end
  end
end

RSpec.shared_examples 'Debian repository upload authorize request' do |status, body = nil|
  and_body = body.nil? ? '' : ' and expected body'

  if status == :created
    it 'authorizes package file upload', :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      expect(json_response['TempPath']).to eq(Packages::PackageFileUploader.workhorse_local_upload_path)
      expect(json_response['RemoteObject']).to be_nil
      expect(json_response['MaximumSize']).to be_nil
    end

    context 'without a valid token' do
      let(:workhorse_token) { 'invalid' }

      it 'rejects request' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'bypassing gitlab-workhorse' do
      let(:workhorse_headers) { {} }

      it 'rejects request' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  else
    it "returns #{status}#{and_body}", :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(status)

      unless body.nil?
        expect(response.body).to eq(body)
      end
    end
  end
end

RSpec.shared_examples 'rejects Debian access with unknown container id' do
  context 'with an unknown container' do
    let(:container) { double(id: non_existing_record_id) }

    context 'as anonymous' do
      it_behaves_like 'Debian repository GET request', :unauthorized, nil
    end

    context 'as authenticated user' do
      subject { get api(url), headers: basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'Debian repository GET request', :not_found, nil
    end
  end
end

RSpec.shared_examples 'Debian repository read endpoint' do |desired_behavior, success_status, success_body|
  context 'with valid container' do
    using RSpec::Parameterized::TableSyntax

    where(:visibility_level, :user_role, :member, :user_token, :expected_status, :expected_body) do
      :public  | :developer  | true  | true  | success_status | success_body
      :public  | :guest      | true  | true  | success_status | success_body
      :public  | :developer  | true  | false | success_status | success_body
      :public  | :guest      | true  | false | success_status | success_body
      :public  | :developer  | false | true  | success_status | success_body
      :public  | :guest      | false | true  | success_status | success_body
      :public  | :developer  | false | false | success_status | success_body
      :public  | :guest      | false | false | success_status | success_body
      :public  | :anonymous  | false | true  | success_status | success_body
      :private | :developer  | true  | true  | success_status | success_body
      :private | :guest      | true  | true  | :forbidden     | nil
      :private | :developer  | true  | false | :unauthorized  | nil
      :private | :guest      | true  | false | :unauthorized  | nil
      :private | :developer  | false | true  | :not_found     | nil
      :private | :guest      | false | true  | :not_found     | nil
      :private | :developer  | false | false | :unauthorized  | nil
      :private | :guest      | false | false | :unauthorized  | nil
      :private | :anonymous  | false | true  | :unauthorized  | nil
    end

    with_them do
      include_context 'Debian repository access', params[:visibility_level], params[:user_role], params[:member], params[:user_token], :basic do
        it_behaves_like "Debian repository #{desired_behavior}", params[:expected_status], params[:expected_body]
      end
    end
  end

  it_behaves_like 'rejects Debian access with unknown container id'
end

RSpec.shared_examples 'Debian repository write endpoint' do |desired_behavior, success_status, success_body|
  context 'with valid container' do
    using RSpec::Parameterized::TableSyntax

    where(:visibility_level, :user_role, :member, :user_token, :expected_status, :expected_body) do
      :public  | :developer  | true  | true  | success_status | success_body
      :public  | :guest      | true  | true  | :forbidden     | nil
      :public  | :developer  | true  | false | :unauthorized  | nil
      :public  | :guest      | true  | false | :unauthorized  | nil
      :public  | :developer  | false | true  | :forbidden     | nil
      :public  | :guest      | false | true  | :forbidden     | nil
      :public  | :developer  | false | false | :unauthorized  | nil
      :public  | :guest      | false | false | :unauthorized  | nil
      :public  | :anonymous  | false | true  | :unauthorized  | nil
      :private | :developer  | true  | true  | success_status | success_body
      :private | :guest      | true  | true  | :forbidden     | nil
      :private | :developer  | true  | false | :unauthorized  | nil
      :private | :guest      | true  | false | :unauthorized  | nil
      :private | :developer  | false | true  | :not_found     | nil
      :private | :guest      | false | true  | :not_found     | nil
      :private | :developer  | false | false | :unauthorized  | nil
      :private | :guest      | false | false | :unauthorized  | nil
      :private | :anonymous  | false | true  | :unauthorized  | nil
    end

    with_them do
      include_context 'Debian repository access', params[:visibility_level], params[:user_role], params[:member], params[:user_token], :basic do
        it_behaves_like "Debian repository #{desired_behavior}", params[:expected_status], params[:expected_body]
      end
    end
  end

  it_behaves_like 'rejects Debian access with unknown container id'
end
