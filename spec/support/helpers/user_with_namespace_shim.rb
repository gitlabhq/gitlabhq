# frozen_string_literal: true

# Modify the FactoryBot user build process to assign a personal namespace.
# The complement to this shim is in the User factory where we assign_personal_namespace.
#
# This is needed to assist with the transition to optional personal namespaces.
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137065
module UserWithNamespaceShim
  extend ActiveSupport::Concern

  USER_WITH_NAMESPACE_SHIM_YAML = File.join(__dir__, 'user_with_namespace_shim.yml')

  class << self
    include Gitlab::Utils::StrongMemoize

    def enabled?
      self.enabled ||= false
    end

    def shim(spec_file)
      self.enabled = spec_file_shimmed?(spec_file)
    end

    def unshim
      self.enabled = false
    end

    # Determine the spec filename from the current backtrace.
    def get_spec_file
      caller.find do |line|
        match = line.match(%r{^(.+_spec\.rb|.+/frontend/fixtures/.+\.rb):\d+:in})
        match[1] if match
      end

      path = ::Regexp.last_match(1)
      return unless path

      Pathname.new(path)
              .relative_path_from(Rails.root)
              .to_s
    end

    private

    def spec_file_shimmed?(spec_file)
      shimmed_spec_list.include?(spec_file)
    end

    def shimmed_spec_list
      YAML.load_file(USER_WITH_NAMESPACE_SHIM_YAML) || []
    end
    strong_memoize_attr :shimmed_spec_list

    attr_accessor :enabled
  end

  included do
    # This is our only chance to determine the spec filename.
    spec_file = UserWithNamespaceShim.get_spec_file

    # We need to use before(:all) instead of before_all otherwise we open a transaction before running the example
    # which interferes with examples using the the table deletion strategy like those marked as `:delete`.
    # rubocop:disable RSpec/BeforeAll -- reason above
    before(:all) do
      UserWithNamespaceShim.shim(spec_file)
    end
    # rubocop:enable RSpec/BeforeAll

    after(:all) do
      UserWithNamespaceShim.unshim
    end
  end
end
