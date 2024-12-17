# frozen_string_literal: true

module Support
  # Ensure that finders' `execute` method always returns
  # `ActiveRecord::Relation`.
  #
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/298771
  module FinderCollection
    def self.install_check(finder_class)
      return unless check?(finder_class)

      finder_class.prepend CheckResult
    end

    ALLOWLIST_YAML = File.join(__dir__, 'finder_collection_allowlist.yml')

    def self.check?(finder_class)
      @allowlist ||= YAML.load_file(ALLOWLIST_YAML).to_set

      @allowlist.exclude?(finder_class.name)
    end

    module CheckResult
      def execute(...)
        result = super

        unless result.is_a?(ActiveRecord::Relation)
          raise <<~MESSAGE
            #{self.class}#execute returned `#{result.class}` instead of `ActiveRecord::Relation`.
            All finder classes are expected to return `ActiveRecord::Relation`.

            Read more at https://docs.gitlab.com/ee/development/reusing_abstractions.html#finders
          MESSAGE
        end

        result
      end
    end
  end
end

RSpec.configure do |config|
  config.before(:all, type: :finder) do
    Support::FinderCollection.install_check(described_class)
  end
end
