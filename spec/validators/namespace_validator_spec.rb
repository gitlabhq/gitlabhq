require 'spec_helper'

describe NamespaceValidator do
  let(:validator) { described_class.new(attributes: [:path]) }

  # Pass in a full path to remove the format segment:
  # `/ci/lint(.:format)` -> `/ci/lint`
  def without_format(path)
    path.split('(', 2)[0]
  end

  # Pass in a full path and get the last segment before a wildcard
  # That's not a parameter
  # `/*namespace_id/:project_id/builds/artifacts/*ref_name_and_path`
  #    -> 'artifacts'
  def segment_before_last_wildcard(path)
    path_segments = path.split('/').reject { |segment| segment.empty?  }
    last_wildcard_index = path_segments.rindex { |part| part.starts_with?('*') }

    index_of_non_param_segment = last_wildcard_index - 1
    part_before_wildcard = path_segments[index_of_non_param_segment]
    while parameter?(part_before_wildcard)
      index_of_non_param_segment -= 1
      part_before_wildcard = path_segments[index_of_non_param_segment]
    end

    part_before_wildcard
  end

  def parameter?(path_segment)
    path_segment.starts_with?(':') || path_segment.starts_with?('*')
  end

  let(:all_routes) do
    Rails.application.routes.routes.routes.
      map { |r| r.path.spec.to_s }
  end

  let(:routes_without_format) { all_routes.map { |path| without_format(path) } }

  # Routes not starting with `/:` or `/*`
  # all routes not starting with a param
  let(:routes_not_starting_in_wildcard) { routes_without_format.select { |p| p !~ %r{^/[:*]} } }

  # All routes that start with a namespaced path, that have 1 or more
  # path-segments before having another wildcard parameter.
  # - Starting with paths:
  #   - `/*namespace_id/:project_id/`
  #   - `/*namespace_id/:id/`
  # - Followed by one or more path-parts not starting with `:` or `/`
  # - Followed by a path-part that includes a wildcard parameter `*`
  # At the time of writing these routes match: http://rubular.com/r/QDxulzZlxZ
  STARTING_WITH_NAMESPACE = /^\/\*namespace_id\/:(project_)?id/
  NON_PARAM_PARTS = /[^:*][a-z\-_\/]*/
  ANY_OTHER_PATH_PART = /[a-z\-_\/:]*/
  WILDCARD_SEGMENT = /\*/
  let(:namespaced_wildcard_routes) do
    routes_without_format.select do |p|
      p =~ %r{#{STARTING_WITH_NAMESPACE}\/#{NON_PARAM_PARTS}\/#{ANY_OTHER_PATH_PART}#{WILDCARD_SEGMENT}}
    end
  end

  describe 'TOP_LEVEL_ROUTES' do
    it 'includes all the top level namespaces' do
      top_level_words =  routes_not_starting_in_wildcard.
                           map { |p| p.split('/')[1] }. # Get the first part of the path
                           compact.
                           uniq

      expect(described_class::TOP_LEVEL_ROUTES).to include(*top_level_words)
    end
  end

  describe 'WILDCARD_ROUTES' do
    it 'includes all paths that can be used after a namespace/project path' do
      all_wildcard_paths = namespaced_wildcard_routes.map do |path|
        segment_before_last_wildcard(path)
      end.uniq

      expect(described_class::WILDCARD_ROUTES).to include(*all_wildcard_paths)
    end
  end

  describe '#validation_type' do
    it 'uses top level validation for groups without parent' do
      group = build(:group)

      type = validator.validation_type(group)

      expect(type).to eq(:top_level)
    end

    it 'uses wildcard validation for groups with a parent' do
      group = build(:group, parent: create(:group))

      type = validator.validation_type(group)

      expect(type).to eq(:wildcard)
    end

    it 'uses wildcard validation for a project' do
      project = build(:project)

      type = validator.validation_type(project)

      expect(type).to eq(:wildcard)
    end

    it 'uses strict validation for everything else' do
      type = validator.validation_type(double)

      expect(type).to eq(:strict)
    end
  end
end
