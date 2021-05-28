# frozen_string_literal: true

RSpec.shared_examples 'rejects helm packages access' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    if status == :unauthorized
      it 'has the correct response header' do
        subject

        expect(response.headers['WWW-Authenticate']).to eq 'Basic realm="GitLab Packages Registry"'
      end
    end
  end
end

RSpec.shared_examples 'process helm download content request' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it_behaves_like 'a package tracking event', 'API::HelmPackages', 'pull_package'

    it 'returns a valid package archive' do
      subject

      expect(response.media_type).to eq('application/octet-stream')
    end
  end
end

RSpec.shared_examples 'rejects helm access with unknown project id' do
  context 'with an unknown project' do
    let(:project) { OpenStruct.new(id: 1234567890) }

    context 'as anonymous' do
      it_behaves_like 'rejects helm packages access', :anonymous, :unauthorized
    end

    context 'as authenticated user' do
      subject { get api(url), headers: basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'rejects helm packages access', :anonymous, :not_found
    end
  end
end
