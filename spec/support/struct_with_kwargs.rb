# frozen_string_literal: true

# Detect incompatbilities between Ruby 3.1 and Ruby 3.2+ in the cases where
# Struct.new is missing `keyword_init: true` and a Hash is passed.
#
# See https://gitlab.com/gitlab-org/gitlab/-/issues/474743
module StructWithKwargs
  # Excluding structs we don't own and cannot patch.
  EXCLUDE = %w[
    Aws::S3::EndpointParameters
  ].freeze

  def self.check?(klass)
    !EXCLUDE.include?(klass.name) # rubocop:disable Rails/NegateInclude -- Rails is not always available.
  end

  module Patch
    def new(*args, **kwargs)
      return super if kwargs[:keyword_init]

      super.prepend KwargsCheck
    end
  end

  module KwargsCheck
    def initialize(*args, **kwargs, &block)
      if args.empty? && kwargs.any? && StructWithKwargs.check?(self.class)
        raise <<~MESSAGE
          Passing only keyword arguments to #{self.class}#initialize will behave differently from Ruby 3.2. Please pass `keyword_init: true` to `Struct` constructor or use a Hash literal like .new({k: v}) instead of .new(k: v).
        MESSAGE
      end

      super
    end
  end
end

Struct.singleton_class.prepend StructWithKwargs::Patch
