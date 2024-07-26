# frozen_string_literal: true

module DisableNamespaceOrganizationValidationHelper
  extend ActiveSupport::Concern

  SPECS_FOR_CODE_TO_FIX = File.join(__dir__, 'disable_namespace_organization_validation.yml')

  class << self
    include Gitlab::Utils::StrongMemoize

    def todo_list
      YAML.load_file(SPECS_FOR_CODE_TO_FIX).filter_map { |path| full_path(path) } || []
    end
    strong_memoize_attr :todo_list

    def full_path(path)
      return unless File.exist?(path)

      Pathname.new(path).realpath.to_s
    end
  end

  included do |base|
    spec_file = base.metadata[:absolute_file_path]

    if spec_file.in?(DisableNamespaceOrganizationValidationHelper.todo_list)
      around do |example|
        ::Gitlab::SafeRequestStore.ensure_request_store { example.run }
      end
    end
  end
end
