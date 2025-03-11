# frozen_string_literal: true

module GraphQL
  class Schema
    # This base class accepts configuration for a mutation root field,
    # then it can be hooked up to your mutation root object type.
    #
    # If you want to customize how this class generates types, in your base class,
    # override the various `generate_*` methods.
    #
    # @see {GraphQL::Schema::RelayClassicMutation} for an extension of this class with some conventions built-in.
    #
    # @example Creating a comment
    #  # Define the mutation:
    #  class Mutations::CreateComment < GraphQL::Schema::Mutation
    #    argument :body, String, required: true
    #    argument :post_id, ID, required: true
    #
    #    field :comment, Types::Comment, null: true
    #    field :errors, [String], null: false
    #
    #    def resolve(body:, post_id:)
    #      post = Post.find(post_id)
    #      comment = post.comments.build(body: body, author: context[:current_user])
    #      if comment.save
    #        # Successful creation, return the created object with no errors
    #        {
    #          comment: comment,
    #          errors: [],
    #        }
    #      else
    #        # Failed save, return the errors to the client
    #        {
    #          comment: nil,
    #          errors: comment.errors.full_messages
    #        }
    #      end
    #    end
    #  end
    #
    #  # Hook it up to your mutation:
    #  class Types::Mutation < GraphQL::Schema::Object
    #    field :create_comment, mutation: Mutations::CreateComment
    #  end
    #
    #  # Call it from GraphQL:
    #  result = MySchema.execute <<-GRAPHQL
    #  mutation {
    #    createComment(postId: "1", body: "Nice Post!") {
    #      errors
    #      comment {
    #        body
    #        author {
    #          login
    #        }
    #      }
    #    }
    #  }
    #  GRAPHQL
    #
    class Mutation < GraphQL::Schema::Resolver
      extend GraphQL::Schema::Member::HasFields
      extend GraphQL::Schema::Resolver::HasPayloadType

      # @api private
      def call_resolve(_args_hash)
        # Clear any cached values from `loads` or authorization:
        dataloader.clear_cache
        super
      end

      class << self
        def visible?(context)
          true
        end

        private

        def conflict_field_name_warning(field_defn)
          "#{self.graphql_name}'s `field :#{field_defn.name}` conflicts with a built-in method, use `hash_key:` or `method:` to pick a different resolve behavior for this field (for example, `hash_key: :#{field_defn.resolver_method}_value`, and modify the return hash). Or use `method_conflict_warning: false` to suppress this warning."
        end

        # Override this to attach self as `mutation`
        def generate_payload_type
          payload_class = super
          payload_class.mutation(self)
          payload_class
        end
      end
    end
  end
end
