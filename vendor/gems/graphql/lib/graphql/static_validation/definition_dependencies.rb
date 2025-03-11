# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # Track fragment dependencies for operations
    # and expose the fragment definitions which
    # are used by a given operation
    module DefinitionDependencies
      attr_reader :dependencies

      def initialize(*)
        super
        @defdep_node_paths = {}

        # { name => [node, ...] } pairs for fragments (although duplicate-named fragments are _invalid_, they are _possible_)
        @defdep_fragment_definitions = Hash.new{ |h, k| h[k] = [] }

        # This tracks dependencies from fragment to Node where it was used
        # { fragment_definition_name => [dependent_node, dependent_node]}
        @defdep_dependent_definitions = Hash.new { |h, k| h[k] = Set.new }

        # First-level usages of spreads within definitions
        # (When a key has an empty list as its value,
        #  we can resolve that key's dependents)
        # { definition_node => [node, node ...] }
        @defdep_immediate_dependencies = Hash.new { |h, k| h[k] = Set.new }

        # When we encounter a spread,
        # this node is the one who depends on it
        @defdep_current_parent = nil
      end

      def on_document(node, parent)
        node.definitions.each do |definition|
          if definition.is_a? GraphQL::Language::Nodes::FragmentDefinition
            @defdep_fragment_definitions[definition.name] << definition
          end
        end
        super
        @dependencies = dependency_map { |defn, spreads, frag|
          context.on_dependency_resolve_handlers.each { |h| h.call(defn, spreads, frag) }
        }
      end

      def on_operation_definition(node, prev_node)
        @defdep_node_paths[node.name] = NodeWithPath.new(node, context.path)
        @defdep_current_parent = node
        super
        @defdep_current_parent = nil
      end

      def on_fragment_definition(node, parent)
        @defdep_node_paths[node] = NodeWithPath.new(node, context.path)
        @defdep_current_parent = node
        super
        @defdep_current_parent = nil
      end

      def on_fragment_spread(node, parent)
        @defdep_node_paths[node] = NodeWithPath.new(node, context.path)

        # Track both sides of the dependency
        @defdep_dependent_definitions[node.name] << @defdep_current_parent
        @defdep_immediate_dependencies[@defdep_current_parent] << node
        super
      end

      # A map of operation definitions to an array of that operation's dependencies
      # @return [DependencyMap]
      def dependency_map(&block)
        @dependency_map ||= resolve_dependencies(&block)
      end

      # Map definition AST nodes to the definition AST nodes they depend on.
      # Expose circular dependencies.
      class DependencyMap
        # @return [Array<GraphQL::Language::Nodes::FragmentDefinition>]
        attr_reader :cyclical_definitions

        # @return [Hash<Node, Array<GraphQL::Language::Nodes::FragmentSpread>>]
        attr_reader :unmet_dependencies

        # @return [Array<GraphQL::Language::Nodes::FragmentDefinition>]
        attr_reader :unused_dependencies

        def initialize
          @dependencies = Hash.new { |h, k| h[k] = [] }
          @cyclical_definitions = []
          @unmet_dependencies = Hash.new { |h, k| h[k] = [] }
          @unused_dependencies = []
        end

        # @return [Array<GraphQL::Language::Nodes::AbstractNode>] dependencies for `definition_node`
        def [](definition_node)
          @dependencies[definition_node]
        end
      end

      class NodeWithPath
        extend Forwardable
        attr_reader :node, :path
        def initialize(node, path)
          @node = node
          @path = path
        end

        def_delegators :@node, :name, :eql?, :hash
      end

      private

      # Return a hash of { node => [node, node ... ]} pairs
      # Keys are top-level definitions
      # Values are arrays of flattened dependencies
      def resolve_dependencies
        dependency_map = DependencyMap.new
        # Don't allow the loop to run more times
        # than the number of fragments in the document
        max_loops = 0
        @defdep_fragment_definitions.each_value do |v|
          max_loops += v.size
        end

        loops = 0

        # Instead of tracking independent fragments _as you visit_,
        # determine them at the end. This way, we can treat fragments with the
        # same name as if they were the same name. If _any_ of the fragments
        # with that name has a dependency, we record it.
        independent_fragment_nodes = @defdep_fragment_definitions.values.flatten - @defdep_immediate_dependencies.keys
        visited_fragment_names = Set.new
        while fragment_node = independent_fragment_nodes.pop
          if visited_fragment_names.add?(fragment_node.name)
            # this is a new fragment name
          else
            # this is a duplicate fragment name
            next
          end
          loops += 1
          if loops > max_loops
            raise("Resolution loops exceeded the number of definitions; infinite loop detected. (Max: #{max_loops}, Current: #{loops})")
          end
          # Since it's independent, let's remove it from here.
          # That way, we can use the remainder to identify cycles
          @defdep_immediate_dependencies.delete(fragment_node)
          fragment_usages = @defdep_dependent_definitions[fragment_node.name]
          if fragment_usages.empty?
            # If we didn't record any usages during the visit,
            # then this fragment is unused.
            dependency_map.unused_dependencies << @defdep_node_paths[fragment_node]
          else
            fragment_usages.each do |definition_node|
              # Register the dependency AND second-order dependencies
              dependency_map[definition_node] << fragment_node
              dependency_map[definition_node].concat(dependency_map[fragment_node])
              # Since we've registered it, remove it from our to-do list
              deps = @defdep_immediate_dependencies[definition_node]
              # Can't find a way to _just_ delete from `deps` and return the deleted entries
              removed, remaining = deps.partition { |spread| spread.name == fragment_node.name }
              @defdep_immediate_dependencies[definition_node] = remaining
              if block_given?
                yield(definition_node, removed, fragment_node)
              end
              if remaining.empty? &&
                definition_node.is_a?(GraphQL::Language::Nodes::FragmentDefinition) &&
                definition_node.name != fragment_node.name
                # If all of this definition's dependencies have
                # been resolved, we can now resolve its
                # own dependents.
                #
                # But, it's possible to have a duplicate-named fragment here.
                # Skip it in that case
                independent_fragment_nodes << definition_node
              end
            end
          end
        end

        # If any dependencies were _unmet_
        # (eg, spreads with no corresponding definition)
        # then they're still in there
        @defdep_immediate_dependencies.each do |defn_node, deps|
          deps.each do |spread|
            if !@defdep_fragment_definitions.key?(spread.name)
              dependency_map.unmet_dependencies[@defdep_node_paths[defn_node]] << @defdep_node_paths[spread]
              deps.delete(spread)
            end
          end
          if deps.empty?
            @defdep_immediate_dependencies.delete(defn_node)
          end
        end

        # Anything left in @immediate_dependencies is cyclical
        cyclical_nodes = @defdep_immediate_dependencies.keys.map { |n| @defdep_node_paths[n] }
        # @immediate_dependencies also includes operation names, but we don't care about
        # those. They became nil when we looked them up on `@fragment_definitions`, so remove them.
        cyclical_nodes.compact!
        dependency_map.cyclical_definitions.concat(cyclical_nodes)

        dependency_map
      end
    end
  end
end
