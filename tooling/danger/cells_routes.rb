# frozen_string_literal: true

require "net/http"
require "uri"

require "gitlab/cells/http_router"

module Tooling
  module Danger
    # Reports drift between this branch's routing snapshot and the copy the HTTP
    # Router mirrors.
    module CellsRoutes
      LOCAL_SNAPSHOT = "config/routing/gitlab_routes.json"
      DOCS_URL = "https://docs.gitlab.com/development/cells/http_router/#check-the-http-router-is-in-sync"
      ROUTER_DOCS_URL = "https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/docs/adding-gitlab-routes.md"
      SKIP_LABEL = "pipeline:skip-router-sync"

      # Mirrors the gate's `.if-not-ee` and `.if-jh` guards. `.if-not-ee` keys off
      # CI_PROJECT_NAME, so both gitlab-org/gitlab and gitlab-org/security/gitlab
      # qualify. `.if-jh` then drops the two JiHu paths, needed because
      # gitlab-cn/gitlab also has the name "gitlab".
      CANONICAL_PROJECT_NAME = /\Agitlab(-ee)?\z/
      JIHU_PROJECT_PATHS = %w[gitlab-cn/gitlab gitlab-org-sandbox/gitlab-jh-validation].freeze

      # Mirrors `.if-merge-request-targeting-stable-branch`, which is broader
      # than `helper.stable_branch?`. Agreeing with the gate is the point of the
      # rule, so the guard has to be the gate's guard.
      STABLE_BRANCH = /\A[\d-]+-stable(-ee|-jh)?\z/

      MAX_LISTED_TEMPLATES = 10
      OPEN_TIMEOUT = 5
      READ_TIMEOUT = 20

      def check!
        return unless applicable?

        comparison = compare
        return if comparison.nil? || comparison.identical?

        warn(construct_message(comparison))
      rescue StandardError => e
        # Fail open. The CI job is the gate, so a gitlab.com blip must produce
        # no comment rather than a misleading one.
        puts "cells_routes: #{e.class}: #{e.message}. Ignoring."
      end

      private

      def applicable?
        helper.ci? &&
          ENV["CI_PROJECT_NAME"].to_s.match?(CANONICAL_PROJECT_NAME) &&
          !JIHU_PROJECT_PATHS.include?(ENV["CI_PROJECT_PATH"].to_s) &&
          !helper.mr_target_branch.to_s.match?(STABLE_BRANCH) &&
          helper.all_changed_files.include?(LOCAL_SNAPSHOT)
      end

      def compare
        local_payload = read_local_snapshot
        return unless local_payload

        router_payload = download
        return unless router_payload

        Gitlab::Cells::HttpRouter::SnapshotComparison.new(
          gitlab_payload: local_payload,
          router_payload: router_payload
        )
      end

      def read_local_snapshot
        File.read(LOCAL_SNAPSHOT)
      rescue Errno::ENOENT
        puts "cells_routes: #{LOCAL_SNAPSHOT} does not exist. Ignoring."
        nil
      end

      def download
        uri = URI(snapshot_url)

        response = Net::HTTP.start(
          uri.host, uri.port,
          use_ssl: uri.scheme == "https",
          open_timeout: OPEN_TIMEOUT,
          read_timeout: READ_TIMEOUT
        ) { |http| http.request(build_request(uri)) }

        return response.body if response.is_a?(Net::HTTPSuccess)

        puts "cells_routes: #{snapshot_url} returned #{response.code} #{response.message}. Ignoring."
        nil
      end

      def build_request(uri)
        request = Net::HTTP::Get.new(uri)
        token = Gitlab::Cells::HttpRouter::RouterSnapshot.job_token
        request["JOB-TOKEN"] = token if token
        request
      end

      def snapshot_url
        Gitlab::Cells::HttpRouter::RouterSnapshot.url_from_env
      end

      def construct_message(comparison)
        <<~MSG
          <details>
          <summary>
          HTTP Router route snapshot has drifted from this merge request.
          </summary>

          #{drift_detail(comparison)}
          To fix this, open a paired merge request in
          [the HTTP Router project](https://gitlab.com/gitlab-org/cells/http-router). In that merge
          request, run `npm run download-gitlab-routes -- BRANCH_NAME` and update the vitest
          snapshot. Merge that merge request, then re-run this GitLab pipeline.

          Most new routes need only a refreshed snapshot, but some need a routing rule change.
          Follow the [full procedure](#{ROUTER_DOCS_URL}) to tell the two apart. For background, see
          [Check the HTTP Router is in sync](#{DOCS_URL}).
          #{skip_label_note}
          </details>
        MSG
      end

      def drift_detail(comparison)
        if comparison.formatting_only?
          return <<~DETAIL
            No route was added or removed. Only the file format or extra per-route fields changed.
            The HTTP Router parses this file, so the two copies still have to match byte for byte.
          DETAIL
        end

        lists = [
          template_list(comparison.gitlab_only, "GitLab but not in the HTTP Router"),
          template_list(comparison.router_only, "the HTTP Router but not in GitLab")
        ].compact.join("\n")

        <<~DETAIL
          #{lists}
          This drift means the HTTP Router may send some requests to the wrong Cell. The router
          checks routes only against its own copy of the table, so it does not see this change yet.
        DETAIL
      end

      def skip_label_note
        return "" unless helper.mr_labels.include?(SKIP_LABEL)

        <<~NOTE

          The `#{SKIP_LABEL}` label skipped the `cells-routes:router-in-sync` job for this merge
          request. This warning is now the only signal of the drift, and the drift is still real.
        NOTE
      end

      def template_list(templates, label)
        return if templates.empty?

        listed = templates.first(MAX_LISTED_TEMPLATES).map { |template| "- `#{template}`" }
        listed << "- ... and #{templates.size - MAX_LISTED_TEMPLATES} more" if templates.size > MAX_LISTED_TEMPLATES

        subject = templates.one? ? "route template is" : "route templates are"

        <<~LIST
          #{templates.size} #{subject} in #{label}:

          #{listed.join("\n")}
        LIST
      end
    end
  end
end
