require 'spec_helper'

describe DynamicPathValidator do
  let(:validator) { described_class.new(attributes: [:path]) }

  # Pass in a full path to remove the format segment:
  # `/ci/lint(.:format)` -> `/ci/lint`
  def without_format(path)
    path.split('(', 2)[0]
  end

  # Pass in a full path and get the last segment before a wildcard
  # That's not a parameter
  # `/*namespace_id/:project_id/builds/artifacts/*ref_name_and_path`
  #    -> 'builds/artifacts'
  def path_between_wildcards(path)
    path = path.gsub(STARTING_WITH_NAMESPACE, "")
    path_segments = path.split('/').reject(&:empty?)
    wildcard_index = path_segments.index { |segment| segment.starts_with?('*') }

    segments_before_wildcard = path_segments[0..wildcard_index - 1]

    param_index = segments_before_wildcard.index { |segment| segment.starts_with?(':') }
    if param_index
      segments_before_wildcard = segments_before_wildcard[param_index + 1..-1]
    end

    segments_before_wildcard.join('/')
  end

  # If the path is reserved. Then no conflicting paths can# be created for any
  # route using this reserved word.
  #
  # Both `builds/artifacts` & `artifacts/file` are covered by reserving the word
  # `artifacts`
  def wildcards_include?(path)
    described_class::WILDCARD_ROUTES.include?(path) ||
      path.split('/').any? { |segment| described_class::WILDCARD_ROUTES.include?(segment) }
  end

  let(:all_routes) do
    Rails.application.routes.routes.routes.
      map { |r| r.path.spec.to_s }
  end

  let(:routes_without_format) { all_routes.map { |path| without_format(path) } }

  # Routes not starting with `/:` or `/*`
  # all routes not starting with a param
  let(:routes_not_starting_in_wildcard) { routes_without_format.select { |p| p !~ %r{^/[:*]} } }

  let(:top_level_words) do
    routes_not_starting_in_wildcard.map do |route|
      route.split('/')[1]
    end.compact.uniq
  end

  # All routes that start with a namespaced path, that have 1 or more
  # path-segments before having another wildcard parameter.
  # - Starting with paths:
  #   - `/*namespace_id/:project_id/`
  #   - `/*namespace_id/:id/`
  # - Followed by one or more path-parts not starting with `:` or `*`
  # - Followed by a path-part that includes a wildcard parameter `*`
  # At the time of writing these routes match: http://rubular.com/r/Rv2pDE5Dvw
  STARTING_WITH_NAMESPACE = %r{^/\*namespace_id/:(project_)?id}
  NON_PARAM_PARTS = %r{[^:*][a-z\-_/]*}
  ANY_OTHER_PATH_PART = %r{[a-z\-_/:]*}
  WILDCARD_SEGMENT = %r{\*}
  let(:namespaced_wildcard_routes) do
    routes_without_format.select do |p|
      p =~ %r{#{STARTING_WITH_NAMESPACE}/#{NON_PARAM_PARTS}/#{ANY_OTHER_PATH_PART}#{WILDCARD_SEGMENT}}
    end
  end

  # This will return all paths that are used in a namespaced route
  # before another wildcard path:
  #
  # /*namespace_id/:project_id/builds/artifacts/*ref_name_and_path
  # /*namespace_id/:project_id/info/lfs/objects/*oid
  # /*namespace_id/:project_id/commits/*id
  # /*namespace_id/:project_id/builds/:build_id/artifacts/file/*path
  # -> ['builds/artifacts', 'info/lfs/objects', 'commits', 'artifacts/file']
  let(:all_wildcard_paths) do
    namespaced_wildcard_routes.map do |route|
      path_between_wildcards(route)
    end.uniq
  end

  describe 'TOP_LEVEL_ROUTES' do
    it 'includes all the top level namespaces' do
      expect(described_class::TOP_LEVEL_ROUTES).to include(*top_level_words)
    end
  end

  describe 'WILDCARD_ROUTES' do
    it 'includes all paths that can be used after a namespace/project path' do
      aggregate_failures do
        all_wildcard_paths.each do |path|
          expect(wildcards_include?(path)).to be(true), "Expected #{path} to be rejected"
        end
      end
    end
  end

  describe '.contains_path_part?' do
    it 'recognizes a path part' do
      expect(described_class.contains_path_part?('user/some/path', 'user')).
        to be_truthy
    end

    it 'recognizes a path ending in the path part' do
      expect(described_class.contains_path_part?('some/path/user', 'user')).
        to be_truthy
    end

    it 'skips partial path matchies' do
      expect(described_class.contains_path_part?('some/user1/path', 'user')).
        to be_falsy
    end

    it 'can recognise combined paths' do
      expect(described_class.contains_path_part?('some/user/admin/path', 'user/admin')).
        to be_truthy
    end

    it 'only recognizes full paths' do
      expect(described_class.contains_path_part?('frontend-fixtures', 's')).
        to be_falsy
    end

    it 'handles regex chars gracefully' do
      expect(described_class.contains_path_part?('frontend-fixtures', '-')).
        to be_falsy
    end
  end

  describe ".valid?" do
    it 'is not case sensitive' do
      expect(described_class.valid?("Users")).to be(false)
    end

    it "isn't valid when the top level is reserved" do
      test_path = 'u/should-be-a/reserved-word'

      expect(described_class.valid?(test_path)).to be(false)
    end

    it "isn't valid if any of the path segments is reserved" do
      test_path = 'the-wildcard/wikis/is-not-allowed'

      expect(described_class.valid?(test_path)).to be(false)
    end

    it "is valid if the path doesn't contain reserved words" do
      test_path = 'there-are/no-wildcards/in-this-path'

      expect(described_class.valid?(test_path)).to be(true)
    end
  end
end
