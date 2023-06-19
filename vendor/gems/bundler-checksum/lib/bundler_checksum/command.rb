# frozen_string_literal: true

module BundlerChecksum
  module Command
    autoload :Init, File.expand_path("command/init", __dir__)
    autoload :Lint, File.expand_path("command/lint", __dir__)
    autoload :Verify, File.expand_path("command/verify", __dir__)
    autoload :Helper, File.expand_path("command/helper", __dir__)

    def self.execute(args)
      if args.empty?
        $stderr.puts 'A command must be given [init,update,verify,lint]'
      end

      case args.first
      when 'init'
        Init.execute
      when 'update'
        $stderr.puts 'Not implemented, please use init'
      when 'lint'
        linted = Lint.execute

        unless linted
          exit 1
        end
      when 'verify'
        verified = Verify.execute

        unless verified
          exit 1
        end
      end
    end
  end
end
