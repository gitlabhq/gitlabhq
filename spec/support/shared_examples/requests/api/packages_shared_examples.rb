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
    let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token).merge(workhorse_headers) }

    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    end

    context 'valid token' do
      it_behaves_like 'returning response status', :success
    end

    context 'invalid token' do
      let(:headers) { basic_auth_header(deploy_token.username, 'bar').merge(workhorse_headers) }

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

RSpec.shared_examples 'job token for package GET requests' do
  context 'with job token headers' do
    let(:headers) { basic_auth_header(::Gitlab::Auth::CI_JOB_USER, job.token) }

    subject { get api(url), headers: headers }

    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      project.add_developer(user)
    end

    context 'valid token' do
      it_behaves_like 'returning response status', :success
    end

    context 'invalid token' do
      let(:headers) { basic_auth_header(::Gitlab::Auth::CI_JOB_USER, 'bar') }

      it_behaves_like 'returning response status', :unauthorized
    end

    context 'invalid user' do
      let(:headers) { basic_auth_header('foo', job.token) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end
end

RSpec.shared_examples 'enforcing read_packages job token policy' do
  it_behaves_like 'enforcing job token policies', :read_packages do
    let(:headers) { job_basic_auth_header(target_job) }
  end
end

RSpec.shared_examples 'job token for package uploads' do |authorize_endpoint: false, accept_invalid_username: false|
  context 'with job token headers' do
    let(:headers) { basic_auth_header(::Gitlab::Auth::CI_JOB_USER, job.token).merge(workhorse_headers) }

    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      project.add_developer(user)
    end

    context 'valid token' do
      it_behaves_like 'returning response status', :success

      unless authorize_endpoint
        it 'creates a package with build info' do
          expect { subject }.to change { Packages::Package.count }.by(1)

          pkg = ::Packages::Package.order_created
                                   .last

          expect(pkg.build_infos).to be_present
        end
      end
    end

    context 'invalid token' do
      let(:headers) { basic_auth_header(::Gitlab::Auth::CI_JOB_USER, 'bar').merge(workhorse_headers) }

      it_behaves_like 'returning response status', :unauthorized
    end

    context 'invalid user' do
      let(:headers) { basic_auth_header('foo', job.token).merge(workhorse_headers) }

      if accept_invalid_username
        it_behaves_like 'returning response status', :success
      else
        it_behaves_like 'returning response status', :unauthorized
      end
    end
  end
end

RSpec.shared_examples 'a package tracking event' do |category, action, service_ping_context = true|
  let(:context) do
    [
      Gitlab::Tracking::ServicePingContext.new(
        data_source: :redis_hll,
        event: snowplow_gitlab_standard_context[:property]
      ).to_h
    ]
  end

  it "creates a gitlab tracking event #{action}", :snowplow, :aggregate_failures do
    subject

    if service_ping_context
      expect_snowplow_event(
        category: category,
        action: action,
        label: "redis_hll_counters.user_packages.user_packages_total_unique_counts_monthly",
        context: context,
        **snowplow_gitlab_standard_context
      )
    else
      expect_snowplow_event(category: category, action: action, **snowplow_gitlab_standard_context)
    end
  end
end

RSpec.shared_examples 'not a package tracking event' do |category, action|
  it 'does not create a gitlab tracking event', :snowplow, :aggregate_failures do
    subject

    expect_no_snowplow_event category: category, action: action
  end
end

RSpec.shared_examples 'bumping the package last downloaded at field' do
  it 'bumps last_downloaded_at' do
    expect { subject }
      .to change { package.reload.last_downloaded_at }.from(nil).to(instance_of(ActiveSupport::TimeWithZone))
  end
end

RSpec.shared_examples 'a successful package creation' do
  it 'creates npm package with file' do
    expect { subject }
      .to change { project.packages.count }.by(1)
      .and change { Packages::PackageFile.count }.by(1)
      .and change { Packages::Tag.count }.by(1)
      .and change { Packages::Npm::Metadatum.count }.by(1)

    expect(response).to have_gitlab_http_status(:ok)
  end
end
