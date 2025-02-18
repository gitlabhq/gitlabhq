# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Releases, :aggregate_failures, feature_category: :release_orchestration do
  let(:project) { create(:project, :repository, :private) }
  let(:maintainer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:developer) { create(:user) }
  let(:guest) { create(:user) }
  let(:non_project_member) { create(:user) }
  let(:commit) { create(:commit, project: project) }

  before do
    project.add_maintainer(maintainer)
    project.add_reporter(reporter)
    project.add_guest(guest)
    project.add_developer(developer)
  end

  describe 'GET /projects/:id/releases', :use_clean_rails_redis_caching do
    it_behaves_like 'enforcing job token policies', :read_releases do
      let(:user) { developer }
      let(:request) do
        get api("/projects/#{source_project.id}/releases"), params: { job_token: target_job.token }
      end
    end

    context 'when there are two releases' do
      let!(:release_1) do
        create(:release, project: project, tag: 'v0.1', author: maintainer, released_at: 2.days.ago)
      end

      let!(:release_2) do
        create(:release, project: project, tag: 'v0.2', author: maintainer, released_at: 1.day.ago)
      end

      it 'returns 200 HTTP status' do
        get api("/projects/#{project.id}/releases", maintainer)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns 200 HTTP status when using JOB-TOKEN auth' do
        job = create(:ci_build, :running, project: project, user: maintainer)

        get api("/projects/#{project.id}/releases"), params: { job_token: job.token }

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns releases ordered by released_at' do
        get api("/projects/#{project.id}/releases", maintainer)

        expect(json_response.count).to eq(2)
        expect(json_response.first['tag_name']).to eq(release_2.tag)
        expect(json_response.second['tag_name']).to eq(release_1.tag)
      end

      it 'does not include description_html' do
        get api("/projects/#{project.id}/releases", maintainer)

        expect(json_response.map { |h| h['description_html'] }).to contain_exactly(nil, nil)
      end

      RSpec.shared_examples 'release sorting' do |order_by|
        subject { get api(url, access_level), params: { sort: sort, order_by: order_by } }

        context "sorting by #{order_by}" do
          context 'ascending order' do
            let(:sort) { 'asc' }

            it 'returns the sorted releases' do
              subject

              expect(json_response.map { |release| release['name'] }).to eq(releases.map(&:name))
            end
          end

          context 'descending order' do
            let(:sort) { 'desc' }

            it 'returns the sorted releases' do
              subject

              expect(json_response.map { |release| release['name'] }).to eq(releases.reverse.map(&:name))
            end
          end
        end
      end

      context 'return releases in sorted order' do
        before do
          release_2.update_attribute(:created_at, 3.days.ago)
        end

        let(:url) { "/projects/#{project.id}/releases" }
        let(:access_level) { maintainer }

        it_behaves_like 'release sorting', 'released_at' do
          let(:releases) { [release_1, release_2] }
        end

        it_behaves_like 'release sorting', 'created_at' do
          let(:releases) { [release_2, release_1] }
        end
      end

      it 'matches response schema' do
        get api("/projects/#{project.id}/releases", maintainer)

        expect(response).to match_response_schema('public_api/v4/releases')
      end

      it 'returns rendered helper paths' do
        get api("/projects/#{project.id}/releases", maintainer)

        expect(json_response.first['commit_path']).to eq("/#{release_2.project.full_path}/-/commit/#{release_2.commit.id}")
        expect(json_response.first['tag_path']).to eq("/#{release_2.project.full_path}/-/tags/#{release_2.tag}")
        expect(json_response.second['commit_path']).to eq("/#{release_1.project.full_path}/-/commit/#{release_1.commit.id}")
        expect(json_response.second['tag_path']).to eq("/#{release_1.project.full_path}/-/tags/#{release_1.tag}")
      end

      context 'when include_html_description option is true' do
        it 'includes description_html field' do
          get api("/projects/#{project.id}/releases", maintainer), params: { include_html_description: true }

          expect(json_response.map { |h| h['description_html'] })
            .to contain_exactly(instance_of(String), instance_of(String))
        end
      end
    end

    it 'returns an upcoming_release status for a future release' do
      tomorrow = Time.now.utc + 1.day
      create(:release, project: project, tag: 'v0.1', author: maintainer, released_at: tomorrow)

      get api("/projects/#{project.id}/releases", maintainer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.first['upcoming_release']).to eq(true)
    end

    it 'returns an upcoming_release status for a past release' do
      yesterday = Time.now.utc - 1.day
      create(:release, project: project, tag: 'v0.1', author: maintainer, released_at: yesterday)

      get api("/projects/#{project.id}/releases", maintainer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.first['upcoming_release']).to eq(false)
    end

    it 'filters by updated_at' do
      create(:release, project: project, tag: 'v0.1', author: maintainer, released_at: 1.day.ago, updated_at: 1.day.ago)
      release = create(:release, project: project, tag: 'v0.2', author: maintainer, released_at: 1.day.ago, updated_at: 4.days.ago)

      get api("/projects/#{project.id}/releases", maintainer), params: { updated_before: 2.days.ago }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.map { |p| p['tag_name'] }).to match([release.tag])
    end

    it 'avoids N+1 queries', :use_sql_query_cache do
      create(:release, :with_evidence, project: project, tag: 'v0.1', author: maintainer)
      create(:release_link, release: project.releases.first)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        get api("/projects/#{project.id}/releases", maintainer)
      end

      create_list(:release, 2, :with_evidence, project: project, author: maintainer)
      create_list(:release, 2, project: project)
      create_list(:release_link, 2, release: project.releases.first)
      create_list(:release_link, 2, release: project.releases.last)

      expect do
        get api("/projects/#{project.id}/releases", maintainer)
      end.not_to exceed_all_query_limit(control)
    end

    it 'serializes releases for the first time and read cached data from the second time' do
      create_list(:release, 2, project: project)

      expect(API::Entities::Release)
        .to receive(:represent).with(instance_of(Release), any_args)
        .twice

      5.times { get api("/projects/#{project.id}/releases", maintainer) }
    end

    it 'increments the cache key when link is updated' do
      releases = create_list(:release, 2, project: project)

      expect(API::Entities::Release)
        .to receive(:represent).with(instance_of(Release), any_args)
        .exactly(4).times

      2.times { get api("/projects/#{project.id}/releases", maintainer) }

      releases.each { |release| create(:release_link, release: release) }

      3.times { get api("/projects/#{project.id}/releases", maintainer) }
    end

    it 'increments the cache key when evidence is updated' do
      releases = create_list(:release, 2, project: project)

      expect(API::Entities::Release)
        .to receive(:represent).with(instance_of(Release), any_args)
        .exactly(4).times

      2.times { get api("/projects/#{project.id}/releases", maintainer) }

      releases.each { |release| create(:evidence, release: release) }

      3.times { get api("/projects/#{project.id}/releases", maintainer) }
    end

    context 'when tag does not exist in git repository' do
      let!(:release) { create(:release, project: project, tag: 'v1.1.5') }

      it 'returns the tag' do
        get api("/projects/#{project.id}/releases", maintainer)

        expect(json_response.count).to eq(1)
        expect(json_response.first['tag_name']).to eq('v1.1.5')
        expect(release).to be_tag_missing
      end
    end

    context 'when tag contains a slash' do
      let!(:release) { create(:release, project: project, tag: 'debian/2.4.0-1', description: "debian/2.4.0-1") }

      it 'returns 200 HTTP status' do
        get api("/projects/#{project.id}/releases", maintainer)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response[0]['tag_path']).to include('%2F') # properly escape the slash
      end
    end

    context 'when user is a guest' do
      let!(:release) do
        create(:release, project: project, tag: 'v0.1', author: maintainer, created_at: 2.days.ago)
      end

      it 'responds 200 OK' do
        get api("/projects/#{project.id}/releases", guest)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it "does not expose tag, commit, source code or helper paths" do
        get api("/projects/#{project.id}/releases", guest)

        expect(response).to match_response_schema('public_api/v4/release/releases_for_guest')
        expect(json_response[0]['assets']['count']).to eq(release.links.count)
        expect(json_response[0]['commit_path']).to be_nil
        expect(json_response[0]['tag_path']).to be_nil
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'responds 200 OK' do
          get api("/projects/#{project.id}/releases", guest)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it "exposes tag, commit, source code and helper paths" do
          get api("/projects/#{project.id}/releases", guest)

          expect(response).to match_response_schema('public_api/v4/releases')
          expect(json_response.first['assets']['count']).to eq(release.links.count + release.sources.count)
          expect(json_response.first['commit_path']).to eq("/#{release.project.full_path}/-/commit/#{release.commit.id}")
          expect(json_response.first['tag_path']).to eq("/#{release.project.full_path}/-/tags/#{release.tag}")
        end
      end
    end

    context 'when user is not a project member' do
      it 'cannot find the project' do
        get api("/projects/#{project.id}/releases", non_project_member)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'allows the request' do
          get api("/projects/#{project.id}/releases", non_project_member)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when releases are public and request user is absent' do
      let(:project) { create(:project, :repository, :public) }

      it 'returns the releases' do
        create(:release, project: project, tag: 'v0.1')

        get api("/projects/#{project.id}/releases")

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq(1)
        expect(json_response.first['tag_name']).to eq('v0.1')
      end
    end
  end

  describe 'GET /projects/:id/releases/:tag_name' do
    context 'when there is a release' do
      let!(:release) do
        create(
          :release,
          project: project,
          tag: 'v0.1',
          sha: commit.id,
          author: maintainer,
          description: 'This is v0.1'
        )
      end

      it_behaves_like 'enforcing job token policies', :read_releases do
        let(:user) { developer }
        let(:request) do
          get api("/projects/#{source_project.id}/releases/v0.1"), params: { job_token: target_job.token }
        end
      end

      it 'returns 200 HTTP status' do
        get api("/projects/#{project.id}/releases/v0.1", maintainer)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns 200 HTTP status when using JOB-TOKEN auth' do
        job = create(:ci_build, :running, project: project, user: maintainer)

        get api("/projects/#{project.id}/releases/v0.1"), params: { job_token: job.token }

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns a release entry' do
        get api("/projects/#{project.id}/releases/v0.1", maintainer)

        expect(json_response['tag_name']).to eq(release.tag)
        expect(json_response['description']).to eq('This is v0.1')
        expect(json_response['author']['name']).to eq(maintainer.name)
        expect(json_response['commit']['id']).to eq(commit.id)
        expect(json_response['assets']['count']).to eq(4)
        expect(json_response['commit_path']).to eq("/#{release.project.full_path}/-/commit/#{release.commit.id}")
        expect(json_response['tag_path']).to eq("/#{release.project.full_path}/-/tags/#{release.tag}")
      end

      it 'matches response schema' do
        get api("/projects/#{project.id}/releases/v0.1", maintainer)

        expect(response).to match_response_schema('public_api/v4/release')
      end

      it 'contains source information as assets' do
        get api("/projects/#{project.id}/releases/v0.1", maintainer)

        expect(json_response['assets']['sources'].map { |h| h['format'] })
          .to match_array(release.sources.map(&:format))
        expect(json_response['assets']['sources'].map { |h| h['url'] })
          .to match_array(release.sources.map(&:url))
      end

      it 'does not include description_html' do
        get api("/projects/#{project.id}/releases/v0.1", maintainer)

        expect(json_response['description_html']).to eq(nil)
      end

      context 'with evidence' do
        let!(:evidence) { create(:evidence, release: release) }

        it 'returns the evidence' do
          get api("/projects/#{project.id}/releases/v0.1", maintainer)

          expect(json_response['evidences'].count).to eq(1)
        end

        it '#collected_at' do
          travel_to(Time.now.round) do
            get api("/projects/#{project.id}/releases/v0.1", maintainer)

            expect(json_response['evidences'].first['collected_at'].to_datetime.to_i).to be_within(1.minute).of(release.evidences.first.created_at.to_i)
          end
        end
      end

      context 'when release is associated to mutiple milestones' do
        context 'milestones order' do
          let_it_be(:project) { create(:project, :repository, :public) }
          let_it_be_with_reload(:release_with_milestones) { create(:release, tag: 'v3.14', project: project) }

          let(:actual_milestone_title_order) do
            get api("/projects/#{project.id}/releases/#{release_with_milestones.tag}", non_project_member)

            json_response['milestones'].map { |m| m['title'] }
          end

          before do
            release_with_milestones.update!(milestones: [milestone_2, milestone_1])
          end

          it_behaves_like 'correct release milestone order'
        end
      end

      context 'when release has link asset' do
        let!(:link) do
          create(:release_link, release: release, name: 'release-18.04.dmg', url: url)
        end

        let(:url) { 'https://my-external-hosting.example.com/scrambled-url/app.zip' }

        it 'contains link information as assets' do
          get api("/projects/#{project.id}/releases/v0.1", maintainer)

          expect(json_response['assets']['links'].count).to eq(1)
          expect(json_response['assets']['links'].first['id']).to eq(link.id)
          expect(json_response['assets']['links'].first['name'])
            .to eq('release-18.04.dmg')
          expect(json_response['assets']['links'].first['url'])
            .to eq('https://my-external-hosting.example.com/scrambled-url/app.zip')
        end
      end

      context 'when include_html_description option is true' do
        it 'includes description_html field' do
          get api("/projects/#{project.id}/releases/v0.1", maintainer), params: { include_html_description: true }

          expect(json_response['description_html']).to be_instance_of(String)
        end
      end

      context 'when user is a guest' do
        it 'responds 403 Forbidden' do
          get api("/projects/#{project.id}/releases/v0.1", guest)

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        context 'when project is public' do
          let(:project) { create(:project, :repository, :public) }

          it 'responds 200 OK' do
            get api("/projects/#{project.id}/releases/v0.1", guest)

            expect(response).to have_gitlab_http_status(:ok)
          end

          it "exposes tag and commit" do
            create(:release, project: project, tag: 'v0.0.1', author: maintainer, created_at: 2.days.ago)
            get api("/projects/#{project.id}/releases/v0.0.1", guest)

            expect(response).to match_response_schema('public_api/v4/release')
          end
        end
      end
    end

    context 'when specified tag is not found in the project' do
      it 'returns 404 for maintainer' do
        get api("/projects/#{project.id}/releases/non_exist_tag", maintainer)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Not Found')
      end

      it 'returns project not found for no user' do
        get api("/projects/#{project.id}/releases/non_exist_tag", nil)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'returns forbidden for guest' do
        get api("/projects/#{project.id}/releases/non_existing_tag", guest)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is not a project member' do
      let!(:release) { create(:release, tag: 'v0.1', project: project) }

      it 'cannot find the project' do
        get api("/projects/#{project.id}/releases/v0.1", non_project_member)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'allows the request' do
          get api("/projects/#{project.id}/releases/v0.1", non_project_member)

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'when release is associated to a milestone' do
          let!(:release) do
            create(:release, tag: 'v0.1', project: project, milestones: [milestone])
          end

          let(:milestone) { create(:milestone, project: project) }

          it 'matches schema' do
            get api("/projects/#{project.id}/releases/v0.1", non_project_member)

            expect(response).to match_response_schema('public_api/v4/release')
          end

          it 'exposes milestones' do
            get api("/projects/#{project.id}/releases/v0.1", non_project_member)

            expect(json_response['milestones'].first['title']).to eq(milestone.title)
          end

          it 'returns issue stats for milestone' do
            create_list(:issue, 2, milestone: milestone, project: project)
            create_list(:issue, 3, :closed, milestone: milestone, project: project)

            get api("/projects/#{project.id}/releases/v0.1", non_project_member)

            issue_stats = json_response['milestones'].first["issue_stats"]
            expect(issue_stats["total"]).to eq(5)
            expect(issue_stats["closed"]).to eq(3)
          end

          context 'when project restricts visibility of issues and merge requests' do
            let!(:project) { create(:project, :repository, :public, :issues_private, :merge_requests_private) }

            it 'does not expose milestones' do
              get api("/projects/#{project.id}/releases/v0.1", non_project_member)

              expect(json_response['milestones']).to be_nil
            end
          end

          context 'when project restricts visibility of issues' do
            let!(:project) { create(:project, :repository, :public, :issues_private) }

            it 'exposes milestones' do
              get api("/projects/#{project.id}/releases/v0.1", non_project_member)

              expect(json_response['milestones'].first['title']).to eq(milestone.title)
            end
          end
        end
      end
    end
  end

  describe 'GET /projects/:id/releases/:tag_name/downloads/*direct_asset_path' do
    let!(:release) { create(:release, project: project, tag: 'v0.1', author: maintainer) }
    let!(:link) { create(:release_link, release: release, url: "#{url}#{filepath}", filepath: filepath) }
    let(:filepath) { '/bin/bigfile.exe' }
    let(:url) { 'https://google.com/-/jobs/140463678/artifacts/download' }

    context 'with an invalid release tag' do
      it 'returns 404 for maintater' do
        get api("/projects/#{project.id}/releases/v0.2/downloads#{filepath}", maintainer)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Not Found')
      end

      it 'returns project not found for no user' do
        get api("/projects/#{project.id}/releases/v0.2/downloads#{filepath}", nil)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'returns forbidden for guest' do
        get api("/projects/#{project.id}/releases/v0.2/downloads#{filepath}", guest)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with a valid release tag' do
      context 'when filepath is provided' do
        context 'when filepath exists' do
          it_behaves_like 'enforcing job token policies', :read_releases, expected_success_status: :redirect do
            let(:user) { developer }
            let(:request) do
              get api("/projects/#{source_project.id}/releases/v0.1/downloads#{filepath}"),
                params: { job_token: target_job.token }
            end
          end

          it 'redirects to the file download URL' do
            get api("/projects/#{project.id}/releases/v0.1/downloads#{filepath}", maintainer)

            expect(response).to redirect_to("#{url}#{filepath}")
          end

          it 'redirects to the file download URL when using JOB-TOKEN auth' do
            job = create(:ci_build, :running, project: project, user: maintainer)

            get api("/projects/#{project.id}/releases/v0.1/downloads#{filepath}"), params: { job_token: job.token }

            expect(response).to redirect_to("#{url}#{filepath}")
          end

          context 'when user is a guest' do
            it 'responds 403 Forbidden' do
              get api("/projects/#{project.id}/releases/v0.1/downloads#{filepath}", guest)

              expect(response).to have_gitlab_http_status(:forbidden)
            end

            context 'when project is public' do
              let(:project) { create(:project, :repository, :public) }

              it 'responds 200 OK' do
                get api("/projects/#{project.id}/releases/v0.1/downloads#{filepath}", guest)

                expect(response).to redirect_to("#{url}#{filepath}")
              end
            end
          end
        end

        context 'when direct_asset_path is used' do
          let(:direct_asset_path) { filepath }

          it 'redirects to the file download URL successfully' do
            get api("/projects/#{project.id}/releases/v0.1/downloads#{direct_asset_path}", maintainer)

            expect(response).to redirect_to("#{url}#{direct_asset_path}")
          end
        end

        context 'when filepath does not exists' do
          it 'returns 404 for maintater' do
            get api("/projects/#{project.id}/releases/v0.1/downloads/bin/not_existing.exe", maintainer)

            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response['message']).to eq('404 Not found')
          end

          it 'returns project not found for no user' do
            get api("/projects/#{project.id}/releases/v0.1/downloads/bin/not_existing.exe", nil)

            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response['message']).to eq('404 Project Not Found')
          end

          it 'returns forbidden for guest' do
            get api("/projects/#{project.id}/releases/v0.1/downloads/bin/not_existing.exe", guest)

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end

      context 'when filepath is not provided' do
        it 'returns 404 for maintater' do
          get api("/projects/#{project.id}/releases/v0.1/downloads", maintainer)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns project not found for no user' do
          get api("/projects/#{project.id}/releases/v0.1/downloads", nil)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns forbidden for guest' do
          get api("/projects/#{project.id}/releases/v0.1/downloads", guest)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET /projects/:id/releases/permalink/latest' do
    context 'when there is no release' do
      it 'returns not found' do
        get api("/projects/#{project.id}/releases/permalink/latest", maintainer)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns not found when using JOB-TOKEN auth' do
        job = create(:ci_build, :running, project: project, user: maintainer)

        get api("/projects/#{project.id}/releases/permalink/latest"), params: { job_token: job.token }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when there are more than one release' do
      let!(:release_a) do
        create(
          :release,
          project: project,
          tag: 'v0.1',
          author: maintainer,
          description: 'This is v0.1',
          released_at: 3.days.ago
        )
      end

      let!(:release_b) do
        create(
          :release,
          project: project,
          tag: 'v0.2',
          author: maintainer,
          description: 'This is v0.2',
          released_at: 2.days.ago
        )
      end

      it_behaves_like 'enforcing job token policies', :read_releases, expected_success_status: :redirect do
        let(:user) { developer }
        let(:request) do
          get api("/projects/#{source_project.id}/releases/permalink/latest"), params: { job_token: target_job.token }
        end
      end

      it 'redirects to the latest release tag' do
        get api("/projects/#{project.id}/releases/permalink/latest", maintainer)

        uri = URI(response.header["Location"])

        expect(response).to have_gitlab_http_status(:redirect)
        expect(uri.path).to eq("/api/v4/projects/#{project.id}/releases/#{release_b.tag}")
      end

      it 'redirects to the latest release tag when using JOB-TOKEN auth' do
        job = create(:ci_build, :running, project: project, user: maintainer)

        get api("/projects/#{project.id}/releases/permalink/latest"), params: { job_token: job.token }

        uri = URI(response.header["Location"])

        expect(response).to have_gitlab_http_status(:redirect)
        expect(uri.path).to eq("/api/v4/projects/#{project.id}/releases/#{release_b.tag}")
      end

      context 'when there are query parameters present' do
        it 'includes the query params on the redirection' do
          get api("/projects/#{project.id}/releases/permalink/latest", maintainer), params: { include_html_description: true, other_param: "aaa" }

          uri = URI(response.header["Location"])
          query_params = Rack::Utils.parse_nested_query(uri.query)

          expect(response).to have_gitlab_http_status(:redirect)
          expect(uri.path).to eq("/api/v4/projects/#{project.id}/releases/#{release_b.tag}")
          expect(query_params).to include({
            "include_html_description" => "true",
            "other_param" => "aaa"
          })
        end

        it 'discards the `order_by` query param' do
          get api("/projects/#{project.id}/releases/permalink/latest", maintainer), params: { order_by: 'something', other_param: "aaa" }

          uri = URI(response.header["Location"])
          query_params = Rack::Utils.parse_nested_query(uri.query)

          expect(response).to have_gitlab_http_status(:redirect)
          expect(uri.path).to eq("/api/v4/projects/#{project.id}/releases/#{release_b.tag}")
          expect(query_params).to include({
            "other_param" => "aaa"
          })
          expect(query_params).not_to include({
            "order_by" => "something"
          })
        end
      end

      context 'when downloading a release asset' do
        it 'redirects to the right endpoint keeping the suffix_path' do
          get api("/projects/#{project.id}/releases/permalink/latest/downloads/bin/example.exe", maintainer)

          uri = URI(response.header["Location"])

          expect(response).to have_gitlab_http_status(:redirect)
          expect(uri.path).to eq("/api/v4/projects/#{project.id}/releases/#{release_b.tag}/downloads/bin/example.exe")
        end

        it 'returns error when there is path traversal in suffix path' do
          # TODO: remove spec once the feature flag is removed
          # https://gitlab.com/gitlab-org/gitlab/-/issues/415460
          stub_feature_flags(check_path_traversal_middleware_reject_requests: false)

          get api("/projects/#{project.id}/releases/permalink/latest/downloads/bin/../../../../../../../password.txt", maintainer)

          expect(response).to have_gitlab_http_status(:bad_request)

          expect(json_response['error']).to eq('suffix_path should be a valid file path')
        end
      end
    end
  end

  describe 'POST /projects/:id/releases' do
    let(:params) do
      {
        name: 'New release',
        tag_name: 'v0.1',
        description: 'Super nice release',
        assets: { links: [link_asset] }
      }
    end

    let(:link_asset) do
      {
        name: 'An example runbook link',
        url: 'https://example.com/runbook',
        link_type: 'runbook',
        filepath: '/permanent/path/to/runbook'
      }
    end

    before do
      initialize_tags
    end

    it_behaves_like 'enforcing job token policies', :admin_releases do
      let(:user) { developer }
      let(:request) do
        post api("/projects/#{source_project.id}/releases"), params: params.merge(job_token: target_job.token)
      end
    end

    it 'accepts the request' do
      post api("/projects/#{project.id}/releases", maintainer), params: params

      expect(response).to have_gitlab_http_status(:created)
    end

    it 'creates a new release' do
      expect do
        post api("/projects/#{project.id}/releases", maintainer), params: params
      end.to change { Release.count }.by(1)

      release = project.releases.last

      aggregate_failures do
        expect(release.name).to eq('New release')
        expect(release.tag).to eq('v0.1')
        expect(release.description).to eq('Super nice release')
        expect(release.links.last.name).to eq('An example runbook link')
        expect(release.links.last.url).to eq('https://example.com/runbook')
        expect(release.links.last.link_type).to eq('runbook')
        expect(release.links.last.filepath).to eq('/permanent/path/to/runbook')
      end
    end

    it 'creates a new release without description' do
      params = {
          name: 'New release without description',
          tag_name: 'v0.1',
          released_at: '2019-03-25 10:00:00'
      }

      expect do
        post api("/projects/#{project.id}/releases", maintainer), params: params
      end.to change { Release.count }.by(1)

      expect(project.releases.last.name).to eq('New release without description')
      expect(project.releases.last.tag).to eq('v0.1')
      expect(project.releases.last.description).to eq(nil)
    end

    it 'sets the released_at to the current time if the released_at parameter is not provided' do
      now = Time.zone.parse('2015-08-25 06:00:00Z')
      travel_to(now) do
        post api("/projects/#{project.id}/releases", maintainer), params: params

        expect(project.releases.last.released_at).to eq(now)
      end
    end

    it 'sets the released_at to the value in the parameters if specified' do
      params = {
        name: 'New release',
        tag_name: 'v0.1',
        description: 'Super nice release',
        released_at: '2019-03-20T10:00:00Z'
      }
      post api("/projects/#{project.id}/releases", maintainer), params: params

      expect(project.releases.last.released_at).to eq('2019-03-20T10:00:00Z')
    end

    it 'assumes the utc timezone for released_at if the timezone is not provided' do
      params = {
        name: 'New release',
        tag_name: 'v0.1',
        description: 'Super nice release',
        released_at: '2019-03-25 10:00:00'
      }
      post api("/projects/#{project.id}/releases", maintainer), params: params

      expect(project.releases.last.released_at).to eq('2019-03-25T10:00:00Z')
    end

    it 'allows specifying a released_at with a local time zone' do
      params = {
        name: 'New release',
        tag_name: 'v0.1',
        description: 'Super nice release',
        released_at: '2019-03-25T10:00:00+09:00'
      }
      post api("/projects/#{project.id}/releases", maintainer), params: params

      expect(project.releases.last.released_at).to eq('2019-03-25T01:00:00Z')
    end

    it 'matches response schema' do
      post api("/projects/#{project.id}/releases", maintainer), params: params

      expect(response).to match_response_schema('public_api/v4/release')
    end

    it 'does not create a new tag' do
      expect do
        post api("/projects/#{project.id}/releases", maintainer), params: params
      end.not_to change { Project.find_by_id(project.id).repository.tag_count }
    end

    context 'when using `direct_asset_path` for the asset link' do
      let(:link_asset) do
        {
          name: 'An example runbook link',
          url: 'https://example.com/runbook',
          link_type: 'runbook',
          direct_asset_path: '/permanent/path/to/runbook'
        }
      end

      it 'creates a new release successfully' do
        expect do
          post api("/projects/#{project.id}/releases", maintainer), params: params
        end.to change { Release.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)

        release = project.releases.last
        expect(release.links.last.filepath).to eq('/permanent/path/to/runbook')
      end
    end

    context 'with protected tag' do
      context 'when user has access to the protected tag' do
        let!(:protected_tag) { create(:protected_tag, :developers_can_create, name: '*', project: project) }

        it 'accepts the request' do
          post api("/projects/#{project.id}/releases", developer), params: params

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'when user does not have access to the protected tag' do
        let!(:protected_tag) { create(:protected_tag, :maintainers_can_create, name: '*', project: project) }

        it 'forbids the request' do
          post api("/projects/#{project.id}/releases", developer), params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when user is a reporter' do
      it 'forbids the request' do
        post api("/projects/#{project.id}/releases", reporter), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is not a project member' do
      it 'forbids the request' do
        post api("/projects/#{project.id}/releases", non_project_member), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'forbids the request' do
          post api("/projects/#{project.id}/releases", non_project_member), params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when create assets altogether' do
        let(:base_params) do
          {
            name: 'New release',
            tag_name: 'v0.1',
            description: 'Super nice release'
          }
        end

        context 'when create one asset' do
          let(:params) do
            base_params.merge({
              assets: {
                links: [{ name: 'beta', url: 'https://dosuken.example.com/inspection.exe' }]
              }
            })
          end

          it 'accepts the request' do
            post api("/projects/#{project.id}/releases", maintainer), params: params

            expect(response).to have_gitlab_http_status(:created)
          end

          it 'creates an asset with specified parameters' do
            post api("/projects/#{project.id}/releases", maintainer), params: params

            expect(json_response['assets']['links'].count).to eq(1)
            expect(json_response['assets']['links'].first['name']).to eq('beta')
            expect(json_response['assets']['links'].first['url'])
              .to eq('https://dosuken.example.com/inspection.exe')
          end

          it 'matches response schema' do
            post api("/projects/#{project.id}/releases", maintainer), params: params

            expect(response).to match_response_schema('public_api/v4/release')
          end
        end

        context 'when creating two assets' do
          let(:params) do
            base_params.merge({
              assets: {
                links: [
                  { name: 'alpha', url: 'https://dosuken.example.com/alpha.exe' },
                  { name: 'beta', url: 'https://dosuken.example.com/beta.exe' }
                ]
              }
            })
          end

          it 'creates two assets with specified parameters' do
            post api("/projects/#{project.id}/releases", maintainer), params: params

            expect(json_response['assets']['links'].count).to eq(2)
            expect(json_response['assets']['links'].map { |h| h['name'] })
              .to match_array(%w[alpha beta])
            expect(json_response['assets']['links'].map { |h| h['url'] })
              .to match_array(%w[https://dosuken.example.com/alpha.exe
                                 https://dosuken.example.com/beta.exe])
          end

          context 'when link names are duplicates' do
            let(:params) do
              base_params.merge({
                assets: {
                  links: [
                    { name: 'alpha', url: 'https://dosuken.example.com/alpha.exe' },
                    { name: 'alpha', url: 'https://dosuken.example.com/beta.exe' }
                  ]
                }
              })
            end

            it 'recognizes as a bad request' do
              post api("/projects/#{project.id}/releases", maintainer), params: params

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end
      end
    end

    context 'when using JOB-TOKEN auth' do
      let(:job) { create(:ci_build, user: maintainer) }
      let(:params) do
        {
          name: 'Another release',
          tag_name: 'v0.2',
          description: 'Another nice release',
          released_at: '2019-04-25T10:00:00+09:00'
        }
      end

      context 'when no token is provided' do
        it 'returns a :not_found error' do
          post api("/projects/#{project.id}/releases"), params: params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when an invalid token is provided' do
        it 'returns an :unauthorized error' do
          post api("/projects/#{project.id}/releases"), params: params.merge(job_token: 'yadayadayada')

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'when a valid token is provided' do
        it 'creates the release for a running job' do
          job.update!(status: :running, project: project)
          post api("/projects/#{project.id}/releases"), params: params.merge(job_token: job.token)

          expect(response).to have_gitlab_http_status(:created)
          expect(project.releases.last.description).to eq('Another nice release')
        end

        it 'returns an :unauthorized error for a completed job' do
          job.success!
          post api("/projects/#{project.id}/releases"), params: params.merge(job_token: job.token)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'when tag does not exist in git repository' do
      let(:params) do
        {
          name: 'Android ~ Ice Cream Sandwich ~',
          tag_name: tag_name,
          description: 'Android 4.0–4.0.4 "Ice Cream Sandwich" is the ninth' \
                       'version of the Android mobile operating system developed' \
                       'by Google.',
          ref: 'master'
        }
      end

      let(:tag_name) { 'v4.0' }

      it 'creates a new tag' do
        expect do
          post api("/projects/#{project.id}/releases", maintainer), params: params
        end.to change { Project.find_by_id(project.id).repository.tag_count }.by(1)

        expect(project.repository.find_tag('v4.0').dereferenced_target.id)
          .to eq(project.repository.commit('master').id)
      end

      it 'creates a new release' do
        expect do
          post api("/projects/#{project.id}/releases", maintainer), params: params
        end.to change { Release.count }.by(1)

        expect(project.releases.last.name).to eq('Android ~ Ice Cream Sandwich ~')
        expect(project.releases.last.tag).to eq('v4.0')
        expect(project.releases.last.description).to eq(
          'Android 4.0–4.0.4 "Ice Cream Sandwich" is the ninth' \
          'version of the Android mobile operating system developed' \
          'by Google.')
      end

      context 'when tag name is HEAD' do
        let(:tag_name) { 'HEAD' }

        it 'returns a 400 error as failure on tag creation' do
          post api("/projects/#{project.id}/releases", maintainer), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq('Tag name invalid')
        end
      end

      context 'when tag name is empty' do
        let(:tag_name) { '' }

        it 'returns a 400 error as failure on tag creation' do
          post api("/projects/#{project.id}/releases", maintainer), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq('Tag name invalid')
        end
      end

      context 'when tag_message is provided' do
        let(:tag_message) { 'Annotated tag message created by Release API' }

        before do
          params.merge!(tag_message: tag_message)
        end

        it 'creates an annotated tag with the tag message' do
          expect do
            post api("/projects/#{project.id}/releases", maintainer), params: params
          end.to change { Project.find_by_id(project.id).repository.tag_count }.by(1)

          expect(project.repository.find_tag(tag_name).message).to eq(tag_message)
        end
      end
    end

    context 'when release already exists' do
      before do
        create(:release, project: project, tag: 'v0.1', name: 'New release')
      end

      it 'returns an error as conflicted request' do
        post api("/projects/#{project.id}/releases", maintainer), params: params

        expect(response).to have_gitlab_http_status(:conflict)
      end
    end

    context 'with milestones' do
      let(:subject) { post api("/projects/#{project.id}/releases", maintainer), params: params }
      let(:milestone) { create(:milestone, project: project, title: 'v1.0') }
      let(:returned_milestones) { json_response['milestones'].map { |m| m['title'] } }

      before do
        params.merge!(milestone_params)

        subject
      end

      context 'with a project milestone' do
        shared_examples 'adds milestone' do
          it 'adds the milestone' do
            expect(response).to have_gitlab_http_status(:created)
            expect(returned_milestones).to match_array(['v1.0'])
          end
        end

        context 'by title' do
          let(:milestone_params) { { milestones: [milestone.title] } }

          it_behaves_like 'adds milestone'
        end

        context 'by id' do
          let(:milestone_params) { { milestone_ids: [milestone.id] } }

          it_behaves_like 'adds milestone'
        end
      end

      context 'with multiple milestones' do
        let(:milestone2) { create(:milestone, project: project, title: 'm2') }
        let(:milestone_params) { { milestones: [milestone.title, milestone2.title] } }

        it 'adds all milestones' do
          expect(response).to have_gitlab_http_status(:created)
          expect(returned_milestones).to match_array(['v1.0', 'm2'])
        end
      end

      context 'with an empty milestone' do
        let(:milestone_params) { { milestones: [] } }

        it 'removes all milestones' do
          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['milestones']).to be_nil
        end
      end

      context 'with a non-existant milestone' do
        let(:milestone_params) { { milestones: ['xyz'] } }

        it 'returns a 400 error as milestone not found' do
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq("Milestone(s) not found: xyz")
        end
      end

      context 'with a milestone from a different project' do
        let(:milestone) { create(:milestone, title: 'v1.0') }
        let(:milestone_params) { { milestones: [milestone.title] } }

        it 'returns a 400 error as milestone not found' do
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq("Milestone(s) not found: v1.0")
        end
      end
    end

    context 'when the project is a catalog resource' do
      let_it_be(:project) { create(:project, :catalog_resource_with_components, create_tag: '6.0.0') }
      let_it_be(:ci_catalog_resource) { create(:ci_catalog_resource, project: project) }

      let(:params) do
        {
          name: 'New release',
          tag_name: '6.0.0',
          description: 'Super nice release'
        }
      end

      it 'creates a new release without publishing the catalog resource' do
        expect do
          post api("/projects/#{project.id}/releases", maintainer), params: params
        end.to change { Release.count }.by(1)

        release = project.releases.last
        expect(release.name).to eq('New release')
        expect(release.catalog_resource_version).to be_nil
      end

      context 'when legacy_catalog_publish is true' do
        let(:params) do
          {
            name: 'New release',
            tag_name: '6.0.0',
            description: 'Super nice release',
            legacy_catalog_publish: true
          }
        end

        it 'creates a new release and publishes the catalog resource' do
          expect do
            post api("/projects/#{project.id}/releases", maintainer), params: params
          end.to change { Release.count }.by(1)

          release = project.releases.last
          expect(release.name).to eq('New release')
          expect(release.catalog_resource_version.catalog_resource).to eq(ci_catalog_resource)
        end
      end

      context 'when the FF ci_release_cli_catalog_publish_option is disabled' do
        before do
          stub_feature_flags(ci_release_cli_catalog_publish_option: false)
        end

        it 'creates a new release and publishes the catalog resource' do
          expect do
            post api("/projects/#{project.id}/releases", maintainer), params: params
          end.to change { Release.count }.by(1)

          release = project.releases.last
          expect(release.name).to eq('New release')
          expect(release.catalog_resource_version.catalog_resource).to eq(ci_catalog_resource)
        end

        context 'when legacy_catalog_publish is true' do
          let(:params) do
            {
              name: 'New release',
              tag_name: '6.0.0',
              description: 'Super nice release',
              legacy_catalog_publish: true
            }
          end

          it 'creates a new release and publishes the catalog resource' do
            expect do
              post api("/projects/#{project.id}/releases", maintainer), params: params
            end.to change { Release.count }.by(1)

            release = project.releases.last
            expect(release.name).to eq('New release')
            expect(release.catalog_resource_version.catalog_resource).to eq(ci_catalog_resource)
          end
        end
      end
    end
  end

  describe 'PUT /projects/:id/releases/:tag_name' do
    let(:params) { { description: 'Best release ever!' } }

    let!(:release) do
      create(
        :release,
        project: project,
        tag: 'v0.1',
        name: 'New release',
        released_at: '2018-03-01T22:00:00Z',
        description: 'Super nice release'
      )
    end

    before do
      initialize_tags
    end

    it_behaves_like 'enforcing job token policies', :admin_releases do
      let(:user) { developer }
      let(:request) do
        put api("/projects/#{source_project.id}/releases/v0.1"), params: params.merge(job_token: target_job.token)
      end
    end

    it 'accepts the request' do
      put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'accepts the request when using JOB-TOKEN auth' do
      job = create(:ci_build, :running, project: project, user: maintainer)

      put api("/projects/#{project.id}/releases/v0.1"), params: params.merge(job_token: job.token)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'updates the description' do
      put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params

      expect(project.releases.last.description).to eq('Best release ever!')
    end

    it 'does not change other attributes' do
      put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params

      expect(project.releases.last.tag).to eq('v0.1')
      expect(project.releases.last.name).to eq('New release')
      expect(project.releases.last.released_at).to eq('2018-03-01T22:00:00Z')
    end

    it 'matches response schema' do
      put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params

      expect(response).to match_response_schema('public_api/v4/release')
    end

    it 'updates released_at' do
      params = { released_at: '2015-10-10T05:00:00Z' }

      put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params

      expect(project.releases.last.released_at).to eq('2015-10-10T05:00:00Z')
    end

    context 'with protected tag' do
      context 'when user has access to the protected tag' do
        let!(:protected_tag) { create(:protected_tag, :developers_can_create, name: '*', project: project) }

        it 'accepts the request' do
          put api("/projects/#{project.id}/releases/v0.1", developer), params: params

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when user does not have access to the protected tag' do
        let!(:protected_tag) { create(:protected_tag, :maintainers_can_create, name: '*', project: project) }

        it 'forbids the request' do
          put api("/projects/#{project.id}/releases/v0.1", developer), params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when user tries to update sha' do
      let(:params) { { sha: 'xxx' } }

      it 'does not allow the request' do
        put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when params is empty' do
      let(:params) { {} }

      it 'does not allow the request' do
        put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when there are no corresponding releases' do
      let!(:release) {}

      it 'forbids the request' do
        put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is a reporter' do
      it 'forbids the request' do
        put api("/projects/#{project.id}/releases/v0.1", reporter), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is not a project member' do
      it 'forbids the request' do
        put api("/projects/#{project.id}/releases/v0.1", non_project_member), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'forbids the request' do
          put api("/projects/#{project.id}/releases/v0.1", non_project_member), params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'with milestones' do
      let(:returned_milestones) { json_response['milestones'].map { |m| m['title'] } }

      subject { put api("/projects/#{project.id}/releases/v0.1", maintainer), params: params }

      context 'when a milestone is passed in' do
        let(:milestone) { create(:milestone, project: project, title: 'v1.0') }
        let!(:milestone2) { create(:milestone, project: project, title: 'v2.0') }

        before do
          release.milestones << milestone
        end

        shared_examples 'updates milestone' do
          it 'updates the milestone' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(returned_milestones).to match_array(['v2.0'])
          end
        end

        context 'by title' do
          let(:params) { { milestones: [milestone2.title] } }

          it_behaves_like 'updates milestone'
        end

        context 'by id' do
          let(:params) { { milestone_ids: [milestone2.id] } }

          it_behaves_like 'updates milestone'
        end

        context 'an identical milestone' do
          let(:params) { { milestones: [milestone.title] } }

          it 'does not change the milestone' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(returned_milestones).to match_array(['v1.0'])
          end
        end

        context 'an empty milestone' do
          let(:params) { { milestones: [] } }

          it 'removes the milestone' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['milestones']).to be_nil
          end
        end

        context 'without milestones parameter' do
          let(:params) { { name: 'some new name' } }

          it 'does not change the milestone' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(returned_milestones).to match_array(['v1.0'])
          end
        end

        context 'multiple milestones' do
          context 'with one new' do
            let!(:milestone2) { create(:milestone, project: project, title: 'milestone2') }
            let(:params) { { milestones: [milestone.title, milestone2.title] } }

            it 'adds the new milestone' do
              subject

              expect(response).to have_gitlab_http_status(:ok)
              expect(returned_milestones).to match_array(['v1.0', 'milestone2'])
            end
          end

          context 'with all new' do
            let!(:milestone2) { create(:milestone, project: project, title: 'milestone2') }
            let!(:milestone3) { create(:milestone, project: project, title: 'milestone3') }

            shared_examples 'update milestones' do
              it 'replaces the milestones' do
                subject

                expect(response).to have_gitlab_http_status(:ok)
                expect(returned_milestones).to match_array(%w[milestone2 milestone3])
              end
            end

            context 'by title' do
              let(:params) { { milestones: [milestone2.title, milestone3.title] } }

              it_behaves_like 'update milestones'
            end

            context 'by id' do
              let(:params) { { milestone_ids: [milestone2.id, milestone3.id] } }

              it_behaves_like 'update milestones'
            end
          end
        end
      end
    end
  end

  describe 'DELETE /projects/:id/releases/:tag_name' do
    let!(:release) do
      create(
        :release,
        project: project,
        tag: 'v0.1',
        name: 'New release',
        description: 'Super nice release'
      )
    end

    it_behaves_like 'enforcing job token policies', :admin_releases do
      let(:user) { developer }
      let(:request) do
        delete api("/projects/#{source_project.id}/releases/v0.1"), params: { job_token: target_job.token }
      end
    end

    it 'accepts the request' do
      delete api("/projects/#{project.id}/releases/v0.1", maintainer)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'accepts the request when using JOB-TOKEN auth' do
      job = create(:ci_build, :running, project: project, user: maintainer)

      delete api("/projects/#{project.id}/releases/v0.1"), params: { job_token: job.token }

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'destroys the release' do
      expect do
        delete api("/projects/#{project.id}/releases/v0.1", maintainer)
      end.to change { Release.count }.by(-1)
    end

    it 'does not remove a tag in repository' do
      expect do
        delete api("/projects/#{project.id}/releases/v0.1", maintainer)
      end.not_to change { Project.find_by_id(project.id).repository.tag_count }
    end

    it 'matches response schema' do
      delete api("/projects/#{project.id}/releases/v0.1", maintainer)

      expect(response).to match_response_schema('public_api/v4/release')
    end

    context 'with protected tag' do
      context 'when user has access to the protected tag' do
        let!(:protected_tag) { create(:protected_tag, :developers_can_create, name: '*', project: project) }

        it 'accepts the request' do
          delete api("/projects/#{project.id}/releases/v0.1", developer)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when user does not have access to the protected tag' do
        let!(:protected_tag) { create(:protected_tag, :maintainers_can_create, name: '*', project: project) }

        it 'forbids the request' do
          delete api("/projects/#{project.id}/releases/v0.1", developer)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when there are no corresponding releases' do
      let!(:release) {}

      it 'forbids the request' do
        delete api("/projects/#{project.id}/releases/v0.1", maintainer)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is a reporter' do
      it 'forbids the request' do
        delete api("/projects/#{project.id}/releases/v0.1", reporter)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is not a project member' do
      it 'forbids the request' do
        delete api("/projects/#{project.id}/releases/v0.1", non_project_member)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public) }

        it 'forbids the request' do
          delete api("/projects/#{project.id}/releases/v0.1", non_project_member)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'Track API events', :snowplow do
    context 'when tracking event with labels from User-Agent' do
      it 'adds the tracked User-Agent to the label of the tracked event' do
        get api("/projects/#{project.id}/releases", maintainer), headers: { 'User-Agent' => described_class::RELEASE_CLI_USER_AGENT }

        assert_snowplow_event('get_releases', true)
      end

      it 'skips label when User-Agent is invalid' do
        get api("/projects/#{project.id}/releases", maintainer), headers: { 'User-Agent' => 'invalid_user_agent' }
        assert_snowplow_event('get_releases', false)
      end
    end
  end

  def initialize_tags
    project.repository.add_tag(maintainer, 'v0.1', commit.id)
    project.repository.add_tag(maintainer, 'v0.2', commit.id)
  end

  def assert_snowplow_event(action, release_cli, user = maintainer)
    expect_snowplow_event(
      category: described_class.name,
      action: action,
      project: project,
      user: user,
      release_cli: release_cli
    )
  end

  describe 'GET /groups/:id/releases' do
    let_it_be(:user1) { create(:user, can_create_group: false) }
    let_it_be(:admin) { create(:admin) }
    let_it_be(:group1) { create(:group) }
    let_it_be(:group2) { create(:group, :private) }
    let_it_be(:project1) { create(:project, namespace: group1) }
    let_it_be(:project2) { create(:project, namespace: group2) }
    let_it_be(:project3) { create(:project, namespace: group1, path: 'test', visibility_level: Gitlab::VisibilityLevel::PRIVATE) }
    let_it_be(:release1) { create(:release, project: project1) }
    let_it_be(:release2) { create(:release, project: project2) }
    let_it_be(:release3) { create(:release, project: project3) }

    it_behaves_like 'GET request permissions for admin mode' do
      let(:path) { "/groups/#{group1.id}/releases" }
    end

    context 'when authenticated as owner', :enable_admin_mode do
      it 'gets releases from all projects in the group' do
        get api("/groups/#{group1.id}/releases", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.length).to eq(2)
        expect(json_response.pluck('name')).to match_array([release1.name, release3.name])
      end

      it 'respects order by parameters' do
        create(:release, project: project1, released_at: DateTime.now + 1.day)
        get api("/groups/#{group1.id}/releases", admin), params: { sort: 'desc' }

        expect(DateTime.parse(json_response[0]["released_at"]))
          .to be > (DateTime.parse(json_response[1]["released_at"]))
      end

      it 'respects the simple parameter' do
        get api("/groups/#{group1.id}/releases", admin), params: { simple: true }

        expect(json_response[0].keys).not_to include("assets")
      end

      it 'denies access to private groups' do
        get api("/groups/#{group2.id}/releases", user1), params: { simple: true }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when authenticated as guest' do
      before do
        group1.add_guest(guest)
      end

      it "does not expose tag, commit, source code or helper paths" do
        get api("/groups/#{group1.id}/releases", guest)

        expect(response).to match_response_schema('public_api/v4/release/releases_for_guest')
        expect(json_response[0]['assets']['count']).to eq(release1.links.count)
        expect(json_response[0]['commit_path']).to be_nil
        expect(json_response[0]['tag_path']).to be_nil
      end
    end

    context 'performance testing' do
      shared_examples 'avoids N+1 queries' do |query_params = {}|
        context 'with subgroups' do
          let(:group) { create(:group) }

          subject { get api("/groups/#{group.id}/releases", admin, admin_mode: true), params: query_params.merge({ include_subgroups: true }) }

          it 'include_subgroups avoids N+1 queries', :use_sql_query_cache do
            subject
            expect(response).to have_gitlab_http_status(:ok)

            control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
              subject
            end

            subgroups = create_list(:group, 10, parent: group1)
            projects = create_list(:project, 10, namespace: subgroups[0])
            create_list(:release, 10, project: projects[0], author: admin)

            expect do
              subject
            end.not_to exceed_all_query_limit(control)
          end
        end
      end

      it_behaves_like 'avoids N+1 queries'
      it_behaves_like 'avoids N+1 queries', { simple: true }
    end
  end
end
