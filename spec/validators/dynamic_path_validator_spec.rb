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
  def path_before_wildcard(path)
    path = path.gsub(STARTING_WITH_NAMESPACE, "")
    path_segments = path.split('/').reject(&:empty?)
    wildcard_index = path_segments.index { |segment| parameter?(segment) }

    segments_before_wildcard = path_segments[0..wildcard_index - 1]

    segments_before_wildcard.join('/')
  end

  def parameter?(segment)
    segment =~ /[*:]/
  end

  # If the path is reserved. Then no conflicting paths can# be created for any
  # route using this reserved word.
  #
  # Both `builds/artifacts` & `build` are covered by reserving the word
  # `build`
  def wildcards_include?(path)
    described_class::WILDCARD_ROUTES.include?(path) ||
      described_class::WILDCARD_ROUTES.include?(path.split('/').first)
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
      path_before_wildcard(route)
    end.uniq
  end

  STARTING_WITH_GROUP = %r{^/groups/\*(group_)?id/}
  let(:group_routes) do
    routes_without_format.select do |path|
      path =~ STARTING_WITH_GROUP
    end
  end

  let(:paths_after_group_id) do
    group_routes.map do |route|
      route.gsub(STARTING_WITH_GROUP, '').split('/').first
    end.uniq
  end

  describe 'TOP_LEVEL_ROUTES' do
    it 'includes all the top level namespaces' do
      expect(described_class::TOP_LEVEL_ROUTES).to include(*top_level_words)
    end
  end

  describe 'GROUP_ROUTES' do
    it "don't contain a second wildcard" do
      expect(described_class::GROUP_ROUTES).to include(*paths_after_group_id)
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

  describe '.without_reserved_wildcard_paths_regex' do
    subject { described_class.without_reserved_wildcard_paths_regex }

    it 'rejects paths starting with a reserved top level' do
      expect(subject).not_to match('dashboard/hello/world')
      expect(subject).not_to match('dashboard')
    end

    it 'matches valid paths with a toplevel word in a different place' do
      expect(subject).to match('parent/dashboard/project-path')
    end

    it 'rejects paths containing a wildcard reserved word' do
      expect(subject).not_to match('hello/edit')
      expect(subject).not_to match('hello/edit/in-the-middle')
      expect(subject).not_to match('foo/bar1/refs/master/logs_tree')
    end

    it 'matches valid paths' do
      expect(subject).to match('parent/child/project-path')
    end
  end

  describe '.regex_excluding_child_paths' do
    let(:subject) { described_class.without_reserved_child_paths_regex }

    it 'rejects paths containing a child reserved word' do
      expect(subject).not_to match('hello/group_members')
      expect(subject).not_to match('hello/activity/in-the-middle')
      expect(subject).not_to match('foo/bar1/refs/master/logs_tree')
    end

    it 'allows a child path on the top level' do
      expect(subject).to match('activity/foo')
      expect(subject).to match('avatar')
    end
  end

  describe ".valid?" do
    it 'is not case sensitive' do
      expect(described_class.valid?("Users")).to be_falsey
    end

    it "isn't valid when the top level is reserved" do
      test_path = 'u/should-be-a/reserved-word'

      expect(described_class.valid?(test_path)).to be_falsey
    end

    it "isn't valid if any of the path segments is reserved" do
      test_path = 'the-wildcard/wikis/is-not-allowed'

      expect(described_class.valid?(test_path)).to be_falsey
    end

    it "is valid if the path doesn't contain reserved words" do
      test_path = 'there-are/no-wildcards/in-this-path'

      expect(described_class.valid?(test_path)).to be_truthy
    end

    it 'allows allows a child path on the last spot' do
      test_path = 'there/can-be-a/project-called/labels'

      expect(described_class.valid?(test_path)).to be_truthy
    end

    it 'rejects a child path somewhere else' do
      test_path = 'there/can-be-no/labels/group'

      expect(described_class.valid?(test_path)).to be_falsey
    end

    it 'rejects paths that are in an incorrect format' do
      test_path = 'incorrect/format.git'

      expect(described_class.valid?(test_path)).to be_falsey
    end
  end

  describe '#path_reserved_for_record?' do
    it 'reserves a sub-group named activity' do
      group = build(:group, :nested, path: 'activity')

      expect(validator.path_reserved_for_record?(group, 'activity')).to be_truthy
    end

    it "doesn't reserve a project called activity" do
      project = build(:project, path: 'activity')

      expect(validator.path_reserved_for_record?(project, 'activity')).to be_falsey
    end
  end

  describe '#validates_each' do
    it 'adds a message when the path is not in the correct format' do
      group = build(:group)

      validator.validate_each(group, :path, "Path with spaces, and comma's!")

      expect(group.errors[:path]).to include(Gitlab::Regex.namespace_regex_message)
    end

    it 'adds a message when the path is not in the correct format' do
      group = build(:group, path: 'users')

      validator.validate_each(group, :path, 'users')

      expect(group.errors[:path]).to include('users is a reserved name')
    end
  end
end
