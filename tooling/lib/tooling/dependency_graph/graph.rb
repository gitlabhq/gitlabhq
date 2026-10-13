# frozen_string_literal: true

require 'pathname'

module Tooling
  module DependencyGraph
    # Dependency graph between the monolith and the gems stored in this repository,
    # built from the `PATH` sources of each bundle's lockfiles.
    class Graph
      MONOLITH = '.'
      GEMSPECS_GLOB = '{gems,vendor/gems}/*/*.gemspec'
      LOCKFILES = %w[Gemfile.lock Gemfile.next.lock].freeze
      PATH_REMOTE_REGEX = /^PATH\n  remote: (.+)$/

      def initialize(root: Dir.pwd)
        @root = Pathname.new(root).expand_path
      end

      # @return [Hash{String => Array<String>}] each bundle directory mapped to the
      #   directories of the in-repo gems in its bundle, as listed in its lockfiles
      def to_h
        @to_h ||= bundle_dirs.to_h { |dir| [dir, dependencies_of(dir)] } # rubocop:disable Rails/IndexWith -- runs under plain Ruby, no ActiveSupport
      end

      # @return [String] the graph as a Mermaid flowchart, with an arrow from each
      #   bundle to each in-repo gem it depends on
      def to_mermaid
        nodes = to_h.keys.map { |dir| "  #{mermaid_id(dir)}[\"#{dir == MONOLITH ? 'monolith' : dir}\"]" }
        edges = to_h.flat_map do |dir, dependencies|
          dependencies.map { |dependency| "  #{mermaid_id(dir)} --> #{mermaid_id(dependency)}" }
        end

        ['flowchart LR', *nodes, *edges].join("\n")
      end

      private

      attr_reader :root

      def mermaid_id(dir)
        dir == MONOLITH ? 'monolith' : dir.tr('^a-zA-Z0-9_', '_')
      end

      def bundle_dirs
        [MONOLITH, *Dir.glob(GEMSPECS_GLOB, base: root).map { |gemspec| File.dirname(gemspec) }.uniq.sort]
      end

      def dependencies_of(dir)
        remotes = LOCKFILES.flat_map do |lockfile|
          path = root.join(dir, lockfile)
          path.exist? ? path.read.scan(PATH_REMOTE_REGEX).flatten : []
        end

        remotes
          .map { |remote| root.join(dir, remote).cleanpath.relative_path_from(root).to_s }
          .reject { |dependency| dependency == dir }
          .uniq
          .sort
      end
    end
  end
end
