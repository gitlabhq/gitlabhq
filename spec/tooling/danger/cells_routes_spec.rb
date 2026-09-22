# frozen_string_literal: true

require 'gitlab/dangerfiles/spec_helper'
require 'fast_spec_helper'
require 'webmock/rspec'

require_relative '../../../danger/plugins/cells_routes'

RSpec.describe Tooling::Danger::CellsRoutes, feature_category: :tooling do
  include_context 'with dangerfile'

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }

  let(:router_url) do
    'https://gitlab.com/api/v4/projects/gitlab-org%2Fcells%2Fhttp-router' \
      '/repository/files/test%2Froutes%2Fgitlab_routes.json/raw?ref=main'
  end

  let(:ci_env)            { true }
  let(:project_name)      { 'gitlab' }
  let(:project_path)      { 'gitlab-org/gitlab' }
  let(:target_branch)     { 'master' }
  let(:changed_files)     { ['config/routing/gitlab_routes.json'] }
  let(:mr_labels)         { [] }
  let(:local_payload)     { payload('/shared') }
  let(:router_payload)    { local_payload }
  let(:router_status)     { 200 }

  subject(:cells_routes) { fake_danger.new(helper: fake_helper) }

  # SnapshotComparison::MIN_ROUTES rejects a short payload as a truncated
  # response, so pad each snapshot up to the floor.
  def payload(*templates, filler: Gitlab::Cells::HttpRouter::SnapshotComparison::MIN_ROUTES, pretty: true)
    routes = Array.new(filler) { |i| { 'template' => "/filler/#{i}", 'example' => "/filler/#{i}" } }
    routes += templates.map { |template| { 'template' => template, 'example' => template } }

    pretty ? "#{JSON.pretty_generate(routes)}\n" : JSON.generate(routes) # rubocop:disable Gitlab/Json -- Danger runs outside Rails
  end

  before do
    stub_const('ENV', { 'CI_PROJECT_NAME' => project_name, 'CI_PROJECT_PATH' => project_path })

    allow(fake_helper).to receive_messages(
      ci?: ci_env,
      mr_target_branch: target_branch,
      all_changed_files: changed_files,
      mr_labels: mr_labels
    )

    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(described_class::LOCAL_SNAPSHOT).and_return(local_payload)

    stub_request(:get, router_url).to_return(status: router_status, body: router_payload)
  end

  describe '#check!' do
    context 'when the snapshots are identical' do
      it 'does not warn' do
        expect(cells_routes).not_to receive(:warn)

        cells_routes.check!
      end
    end

    context 'when the rule does not apply' do
      shared_examples 'a skipped check' do
        it 'does not warn and does not download the router snapshot' do
          expect(cells_routes).not_to receive(:warn)

          cells_routes.check!

          expect(a_request(:get, router_url)).not_to have_been_made
        end
      end

      context 'when not running in CI' do
        let(:ci_env) { false }

        it_behaves_like 'a skipped check'
      end

      context 'when the merge request does not change the snapshot' do
        let(:changed_files)  { ['app/models/user.rb'] }
        let(:router_payload) { payload('/only-router') }

        it_behaves_like 'a skipped check'
      end

      # `.if-merge-request-targeting-stable-branch` covers all three suffixes,
      # and `helper.stable_branch?` only covers `-ee`.
      %w[17-8-stable 17-8-stable-ee 17-8-stable-jh].each do |branch|
        context "when the merge request targets #{branch}" do
          let(:target_branch)  { branch }
          let(:router_payload) { payload('/only-router') }

          it_behaves_like 'a skipped check'
        end
      end

      context 'when the project is FOSS' do
        let(:project_name)   { 'gitlab-foss' }
        let(:project_path)   { 'gitlab-org/gitlab-foss' }
        let(:router_payload) { payload('/only-router') }

        it_behaves_like 'a skipped check'
      end

      # gitlab-cn/gitlab has CI_PROJECT_NAME == "gitlab", so only the path
      # excludes it. gitlab-org-sandbox/gitlab-jh-validation is excluded by name
      # too, but the gate lists it, so the rule has to as well.
      %w[gitlab-cn/gitlab gitlab-org-sandbox/gitlab-jh-validation].each do |path|
        context "when the project is JiHu (#{path})" do
          let(:project_name)   { path == 'gitlab-cn/gitlab' ? 'gitlab' : 'gitlab-jh-validation' }
          let(:project_path)   { path }
          let(:router_payload) { payload('/only-router') }

          it_behaves_like 'a skipped check'
        end
      end
    end

    # gitlab-org/security/gitlab also has CI_PROJECT_NAME == "gitlab", and the
    # gate runs there, so the rule has to run there too.
    context 'when the project is gitlab-org/security/gitlab' do
      let(:project_path)   { 'gitlab-org/security/gitlab' }
      let(:router_payload) { payload('/only-router') }

      it 'runs the check and warns on drift' do
        expect(cells_routes).to receive(:warn)

        cells_routes.check!

        expect(a_request(:get, router_url)).to have_been_made
      end
    end

    context 'when routes drifted' do
      let(:local_payload)  { payload('/only-gitlab', '/shared') }
      let(:router_payload) { payload('/shared', '/only-router') }

      it 'names both sides of the drift' do
        expect(cells_routes).to receive(:warn) do |message|
          expect(message).to include('1 route template is in GitLab but not in the HTTP Router')
          expect(message).to include('1 route template is in the HTTP Router but not in GitLab')
        end

        cells_routes.check!
      end

      it 'lists the drifted templates' do
        expect(cells_routes).to receive(:warn) do |message|
          expect(message).to include('- `/only-gitlab`')
          expect(message).to include('- `/only-router`')
        end

        cells_routes.check!
      end

      it 'links the procedure and the docs, and mentions the escape hatch' do
        expect(cells_routes).to receive(:warn) do |message|
          expect(message).to include(described_class::ROUTER_DOCS_URL)
          expect(message).to include(described_class::DOCS_URL)
          expect(message).to include('npm run download-gitlab-routes')
        end

        cells_routes.check!
      end

      it 'explains the misrouting risk' do
        expect(cells_routes).to receive(:warn).with(
          a_string_including('may send some requests to the wrong Cell')
        )

        cells_routes.check!
      end

      it 'wraps the report in a details block' do
        expect(cells_routes).to receive(:warn).with(a_string_starting_with("<details>\n<summary>"))

        cells_routes.check!
      end

      context 'when only one side drifted' do
        let(:router_payload) { payload('/shared') }

        it 'omits the empty side' do
          expect(cells_routes).to receive(:warn) do |message|
            expect(message).to include('in GitLab but not in the HTTP Router')
            expect(message).not_to include('in the HTTP Router but not in GitLab')
          end

          cells_routes.check!
        end
      end

      context 'when more templates drifted than the cap' do
        # Zero-padded so that the sorted order the comparison returns is also
        # the numeric order, which keeps the assertions below readable.
        let(:extra)         { Array.new(described_class::MAX_LISTED_TEMPLATES + 5) { |i| format('/extra/%02d', i) } }
        let(:local_payload) { payload(*extra) }

        it 'caps the list and counts the remainder' do
          expect(cells_routes).to receive(:warn) do |message|
            expect(message).to include('15 route templates are in GitLab but not in the HTTP Router')
            expect(message).to include('- ... and 5 more')
            expect(message).to include('- `/extra/09`')
            expect(message).not_to include('- `/extra/10`')
          end

          cells_routes.check!
        end
      end

      # The gate resolves these overrides, so the rule has to as well, or the
      # two compare against different files.
      context 'when CELLS_ROUTER_REF repoints the comparison' do
        let(:branch_url) do
          'https://gitlab.com/api/v4/projects/gitlab-org%2Fcells%2Fhttp-router' \
            '/repository/files/test%2Froutes%2Fgitlab_routes.json/raw?ref=my-router-branch'
        end

        before do
          stub_const('ENV',
            { 'CI_PROJECT_NAME' => project_name, 'CI_PROJECT_PATH' => project_path,
              'CELLS_ROUTER_REF' => 'my-router-branch' })
          stub_request(:get, branch_url).to_return(status: 200, body: local_payload)
        end

        it 'compares against that ref and stays silent when it matches' do
          expect(cells_routes).not_to receive(:warn)

          cells_routes.check!

          expect(a_request(:get, branch_url)).to have_been_made
          expect(a_request(:get, router_url)).not_to have_been_made
        end
      end

      context 'when CI_JOB_TOKEN is set' do
        before do
          stub_const('ENV',
            { 'CI_PROJECT_NAME' => project_name, 'CI_PROJECT_PATH' => project_path,
              'CI_JOB_TOKEN' => 'glcbt-test-token' })
        end

        it 'sends the JOB-TOKEN header with the download request' do
          cells_routes.check!

          expect(a_request(:get, router_url).with(headers: { 'JOB-TOKEN' => 'glcbt-test-token' }))
            .to have_been_made
        end
      end

      context 'when the skip label is applied' do
        let(:mr_labels) { [described_class::SKIP_LABEL] }

        it 'still warns, and says the gate was skipped' do
          expect(cells_routes).to receive(:warn).with(
            a_string_including('label skipped the `cells-routes:router-in-sync` job')
          )

          cells_routes.check!
        end
      end
    end

    context 'when only the serialization drifted' do
      let(:local_payload)  { payload('/shared', pretty: true) }
      let(:router_payload) { payload('/shared', pretty: false) }

      it 'says no route was added or removed' do
        expect(cells_routes).to receive(:warn) do |message|
          expect(message).to include('No route was added or removed')
          expect(message).not_to include('but not in')
          # The template sets match, so the misrouting claim would be false.
          expect(message).not_to include('wrong Cell')
        end

        cells_routes.check!
      end
    end

    context 'when the comparison cannot be made' do
      shared_examples 'failing open' do
        it 'does not warn' do
          expect(cells_routes).not_to receive(:warn)

          cells_routes.check!
        end
      end

      context 'when the local snapshot is missing' do
        before do
          allow(File).to receive(:read).with(described_class::LOCAL_SNAPSHOT).and_raise(Errno::ENOENT)
        end

        it_behaves_like 'failing open'
      end

      context 'when the router snapshot is not found' do
        let(:router_status)  { 404 }
        let(:router_payload) { '<!DOCTYPE html>' }

        it_behaves_like 'failing open'
      end

      context 'when gitlab.com returns a server error' do
        let(:router_status)  { 500 }
        let(:router_payload) { '' }

        it_behaves_like 'failing open'
      end

      context 'when the download times out' do
        before do
          stub_request(:get, router_url).to_timeout
        end

        it_behaves_like 'failing open'
      end

      context 'when the router responds with a success but not a snapshot' do
        let(:router_payload) { '<!DOCTYPE html>' }

        it_behaves_like 'failing open'
      end

      context 'when the local snapshot is not a snapshot' do
        let(:local_payload)  { '[]' }
        let(:router_payload) { payload('/shared') }

        it_behaves_like 'failing open'
      end
    end
  end
end
