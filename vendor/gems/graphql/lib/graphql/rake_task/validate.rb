# frozen_string_literal: true

module GraphQL
  class RakeTask
    extend Rake::DSL

    desc "Get the checksum of a graphql-pro version and compare it to published versions on GitHub and graphql-ruby.org"
    task "graphql:pro:validate", [:gem_version] do |t, args|
      version = args[:gem_version]
      if version.nil?
        raise ArgumentError, "A specific version is required, eg `rake graphql:pro:validate[1.12.0]`"
      end
      check = "\e[32m✓\e[0m"
      ex = "\e[31m✘\e[0m"
      puts "Validating graphql-pro v#{version}"
      puts "  - Checking for graphql-pro credentials..."

      creds = `bundle config gems.graphql.pro --parseable`[/[a-z0-9]{11}:[a-z0-9]{11}/]
      if creds.nil?
        puts "    #{ex} failed, please set with `bundle config gems.graphql.pro $MY_CREDENTIALS`"
        exit(1)
      else
        puts "    #{check} found"
      end

      puts "  - Fetching the gem..."
      fetch_result = `gem fetch graphql-pro -v #{version} --source https://#{creds}@gems.graphql.pro`
      if fetch_result.empty?
        puts "    #{ex} failed to fetch v#{version}"
        exit(1)
      else
        puts "    #{check} fetched"
      end

      puts "  - Validating digest..."
      require "digest/sha2"
      gem_digest = Digest::SHA512.new.hexdigest(File.read("graphql-pro-#{version}.gem"))
      require "net/http"
      github_uri = URI("https://raw.githubusercontent.com/rmosolgo/graphql-ruby/master/guides/pro/checksums/graphql-pro-#{version}.txt")
      # Remove final newline from .txt file
      github_digest = Net::HTTP.get(github_uri).chomp

      docs_uri = URI("https://graphql-ruby.org/pro/checksums/graphql-pro-#{version}.txt")
      docs_digest = Net::HTTP.get(docs_uri).chomp

      if docs_digest == gem_digest && github_digest == gem_digest
        puts "    #{check} validated from GitHub"
        puts "    #{check} validated from graphql-ruby.org"
      else
        puts "    #{ex} SHA mismatch:"
        puts "      Downloaded:       #{gem_digest}"
        puts "      GitHub:           #{github_digest}"
        puts "      graphql-ruby.org: #{docs_digest}"
        puts ""
        puts "      This download of graphql-pro is invalid, please open an issue:"
        puts "      https://github.com/rmosolgo/graphql-ruby/issues/new?title=graphql-pro%20digest%20mismatch%20(#{version})"
        exit(1)
      end

      puts "\e[32m✔\e[0m graphql-pro #{version} validated successfully!"
    end
  end
end
