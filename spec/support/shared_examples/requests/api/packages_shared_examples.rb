# frozen_string_literal: true

RSpec.shared_examples 'deploy token for package GET requests' do
  context 'with deploy token headers' do
    let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token) }

    subject { get api(url), headers: headers }

    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    end

    context 'valid token' do
      it_behaves_like 'returning response status', :success
    end

    context 'invalid token' do
      let(:headers) { basic_auth_header(deploy_token.username, 'bar') }

      it_behaves_like 'returning response status', :unauthorized
    end
  end
end

RSpec.shared_examples 'deploy token for package uploads' do
  context 'with deploy token headers' do
    let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token).merge(workhorse_header) }

    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    end

    context 'valid token' do
      it_behaves_like 'returning response status', :success
    end

    context 'invalid token' do
      let(:headers) { basic_auth_header(deploy_token.username, 'bar').merge(workhorse_header) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end
end

RSpec.shared_examples 'does not cause n^2 queries' do
  it 'avoids N^2 database queries' do
    # we create a package to set the baseline for expected queries from 1 package
    create(
      :npm_package,
      name: "@#{project.root_namespace.path}/my-package",
      project: project,
      version: "0.0.1"
    )

    control = ActiveRecord::QueryRecorder.new do
      get api(url)
    end

    5.times do |n|
      create(
        :npm_package,
        name: "@#{project.root_namespace.path}/my-package",
        project: project,
        version: "#{n}.0.0"
      )
    end

    expect do
      get api(url)
    end.not_to exceed_query_limit(control)
  end
end
