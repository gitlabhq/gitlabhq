# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module HasDirectives
        def self.extended(child_cls)
          super
          child_cls.module_exec { self.own_directives = nil }
        end

        def inherited(child_cls)
          super
          child_cls.own_directives = nil
        end

        # Create an instance of `dir_class` for `self`, using `options`.
        #
        # It removes a previously-attached instance of `dir_class`, if there is one.
        #
        # @return [void]
        def directive(dir_class, **options)
          @own_directives ||= []
          HasDirectives.add_directive(self, @own_directives, dir_class, options)
          nil
        end

        # Remove an attached instance of `dir_class`, if there is one
        # @param dir_class [Class<GraphQL::Schema::Directive>]
        # @return [viod]
        def remove_directive(dir_class)
          HasDirectives.remove_directive(@own_directives, dir_class)
          nil
        end

        def directives
          HasDirectives.get_directives(self, @own_directives, :directives)
        end

        class << self
          def add_directive(schema_member, directives, directive_class, directive_options)
            remove_directive(directives, directive_class) unless directive_class.repeatable?
            directives << directive_class.new(schema_member, **directive_options)
          end

          def remove_directive(directives, directive_class)
            directives && directives.reject! { |d| d.is_a?(directive_class) }
          end

          def get_directives(schema_member, directives, directives_method)
            case schema_member
            when Class
              inherited_directives = if schema_member.superclass.respond_to?(directives_method)
                get_directives(schema_member.superclass, schema_member.superclass.public_send(directives_method), directives_method)
              else
                GraphQL::EmptyObjects::EMPTY_ARRAY
              end
              if !inherited_directives.empty? && directives
                dirs = []
                merge_directives(dirs, inherited_directives)
                merge_directives(dirs, directives)
                dirs
              elsif directives
                directives
              elsif !inherited_directives.empty?
                inherited_directives
              else
                GraphQL::EmptyObjects::EMPTY_ARRAY
              end
            when Module
              dirs = nil
              schema_member.ancestors.reverse_each do |ancestor|
                if ancestor.respond_to?(:own_directives) &&
                    !(anc_dirs = ancestor.own_directives).empty?
                  dirs ||= []
                  merge_directives(dirs, anc_dirs)
                end
              end
              if directives
                dirs ||= []
                merge_directives(dirs, directives)
              end
              dirs || GraphQL::EmptyObjects::EMPTY_ARRAY
            when HasDirectives
              directives || GraphQL::EmptyObjects::EMPTY_ARRAY
            else
              raise "Invariant: how could #{schema_member} not be a Class, Module, or instance of HasDirectives?"
            end
          end

          private

          # Modify `target` by adding items from `dirs` such that:
          # - Any name conflict is overridden by the incoming member of `dirs`
          # - Any other member of `dirs` is appended
          # @param target [Array<GraphQL::Schema::Directive>]
          # @param dirs [Array<GraphQL::Schema::Directive>]
          # @return [void]
          def merge_directives(target, dirs)
            dirs.each do |dir|
              if (idx = target.find_index { |d| d.graphql_name == dir.graphql_name })
                target.slice!(idx)
                target.insert(idx, dir)
              else
                target << dir
              end
            end
            nil
          end
        end

        protected

        attr_accessor :own_directives
      end
    end
  end
end
