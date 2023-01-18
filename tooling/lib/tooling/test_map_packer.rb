# frozen_string_literal: true

module Tooling
  class TestMapPacker
    SEPARATOR = '/'
    MARKER = 1

    def pack(map)
      map.transform_values { |tests| create_tree_from_tests(tests) }
    end

    def unpack(compact_map)
      compact_map.transform_values { |tree| retrieve_tests_from_tree(tree) }
    end

    private

    def create_tree_from_tests(tests)
      tests.inject({}) do |tree, test|
        segments = test.split(SEPARATOR)
        branch = create_branch_from_segments(segments)
        deep_merge(tree, branch)
      end
    end

    def create_branch_from_segments(segments)
      segments.reverse.inject(MARKER) { |node, parent| { parent => node } }
    end

    def deep_merge(hash, other)
      hash.merge(other) do |_, this_val, other_val|
        if this_val.is_a?(Hash) && other_val.is_a?(Hash)
          deep_merge(this_val, other_val)
        else
          other_val
        end
      end
    end

    def retrieve_tests_from_tree(tree)
      traverse(tree).inject([]) do |tests, test|
        tests << test
      end
    end

    def traverse(tree, segments = [], &block)
      return to_enum(__method__, tree, segments) unless block

      if tree == MARKER
        return yield segments.join(SEPARATOR)
      end

      tree.each do |key, value|
        traverse(value, segments + [key], &block)
      end
    end
  end
end
