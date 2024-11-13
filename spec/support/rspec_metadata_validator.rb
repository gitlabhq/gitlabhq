# frozen_string_literal: true

# rubocop:disable Gitlab/NamespacedClass -- There is no product domain for this class.
class RspecMetadataValidator
  class UnknownMetadataError < RuntimeError
    def initialize(keys)
      super(<<~MSG)
        Following metadata keys are unknown: #{keys}
        Please fix the key name or update the 'known_rspec_metadata_keys.yml' file.
      MSG
    end
  end

  class << self
    def validate!(metadata)
      extra_keys = metadata.keys - known_keys

      return unless extra_keys.any?

      raise UnknownMetadataError, extra_keys
    end

    private

    def known_keys
      @known_keys ||= YAML.load_file(known_keys_file)
    end

    def known_keys_file
      File.join(__dir__, 'known_rspec_metadata_keys.yml')
    end
  end
end

RspecMetadataValidator.prepend_mod
# rubocop:enable Gitlab/NamespacedClass
