# frozen_string_literal: true
require "yard"
require "webrick"

namespace :apidocs do
  desc "Fetch a gem version from RubyGems, build the docs"
  task :gen_version, [:version] do |t, args|
    # GITHUB_REF comes from GitHub Actions
    version = args[:version] || ENV["GITHUB_REF"] || raise("A version is required")
    puts "Building docs for #{version}"
    # GitHub Actions gives the full tag name
    if version.start_with?("refs/tags/")
      version = version[10..-1]
    end
    if version.start_with?("v")
      version = version[1..-1]
    end
    Dir.mktmpdir do
      puts "Fetching graphql-#{version}"
      system("gem fetch graphql --version=#{version}")
      system("gem unpack graphql-#{version}.gem")
      system("rm graphql-#{version}.gem")

      Dir.chdir("graphql-#{version}") do
        # Copy it into gh-pages for publishing
        # and locally for previewing
        push_dest = File.expand_path("../gh-pages/api-doc/#{version}")
        local_dest = File.expand_path("../guides/_site/api-doc/#{version}")
        puts "Creating directories: #{push_dest.inspect}, #{local_dest.inspect}"
        FileUtils.mkdir_p(push_dest)
        FileUtils.mkdir_p(local_dest)
        system("yardoc")
        puts "Copying from #{Dir.pwd}/doc to #{push_dest}"
        copy_entry "doc", push_dest
        puts "Copying from #{Dir.pwd}/doc to #{local_dest}"
        copy_entry "doc", local_dest
      end
    end
    puts "Successfully generated docs for #{version}"
  end
end

namespace :site do
  desc "View the documentation site locally"
  task serve: [] do # if you need api docs, add `:build_doc` to the list of dependencies
    require "jekyll"
    options = {
      "source"      => File.expand_path("guides"),
      "destination" => File.expand_path("guides/_site"),
      "watch"       => true,
      "serving"     => true
    }
    # Generate the site in server mode.
    puts "Running Jekyll..."
    Jekyll::Commands::Build.process(options)
    Jekyll::Commands::Serve.process(options)
  end

  desc "Get the gh-pages branch locally, make sure it's up-to-date"
  task :fetch_latest do
    # Ensure the gh-pages dir exists so we can generate into it.
    puts "Checking for gh-pages dir..."
    unless File.exist?("./gh-pages")
      puts "Creating gh-pages dir..."
      sh "git clone git@github.com:rmosolgo/graphql-ruby gh-pages"
    end

    # Ensure latest gh-pages branch history.
    Dir.chdir("gh-pages") do
      sh "git checkout gh-pages"
      sh "git pull origin gh-pages"
    end
  end

  desc "Remove all generated HTML (making space to re-generate)"
  task :clean_html do
    # Proceed to purge all files in case we removed a file in this release.
    puts "Cleaning gh-pages directory..."
    purge_exclude = [
      'gh-pages/.',
      'gh-pages/..',
      'gh-pages/.git',
      'gh-pages/.gitignore',
      'gh-pages/api-doc',
    ]

    FileList["gh-pages/{*,.*}"].exclude(*purge_exclude).each do |path|
      sh "rm -rf #{path}"
    end
  end

  desc "Build guides/ into gh-pages/ with Jekyll"
  task :build_html do
    # Copy site to gh-pages dir.
    puts "Building site into gh-pages branch..."
    ENV['JEKYLL_ENV'] = 'production'
    require "jekyll"
    Jekyll::Commands::Build.process({
      "source"       => File.expand_path("guides"),
      "destination"  => File.expand_path("gh-pages"),
      "sass"         => { "style" => "compressed" }
    })

    File.write('gh-pages/.nojekyll', "Prevent GitHub from running Jekyll")
  end

  desc "Commit new docs"
  task :commit_changes do
    puts "Committing and pushing to GitHub Pages..."
    sha = `git rev-parse HEAD`.strip
    Dir.chdir('gh-pages') do
      system "git status"
      system "git add ."
      system "git status"
      system "git commit --allow-empty -m 'Updating to #{sha}.'"
    end
  end

  desc "Push docs to gh-pages branch"
  task :push_commit do
    Dir.chdir('gh-pages') do
      sh "git push origin gh-pages"
    end
  end

  desc "Commit the local site to the gh-pages branch and publish to GitHub Pages"
  task publish: [:build_doc, :update_search_index, :fetch_latest, :clean_html, :build_html, :commit_changes, :push_commit]

  YARD::Rake::YardocTask.new(:prepare_yardoc)

  task build_doc: :prepare_yardoc do
    require_relative "../../lib/graphql/version"

    def to_rubydoc_url(path)
      "/api-doc/#{GraphQL::VERSION}/" + path
        .gsub("::", "/")                        # namespaces
        .sub(/#(.+)$/, "#\\1-instance_method")  # instance methods
        .sub(/\.(.+)$/, "#\\1-class_method")    # class methods
    end

    DOC_TEMPLATE = <<-PAGE
---
layout: doc_stub
search: true
title: %{title}
url: %{url}
rubydoc_url: %{url}
doc_stub: true
---

%{documentation}
PAGE

    puts "Preparing YARD docs @ v#{GraphQL::VERSION} for search index..."
    registry = YARD::Registry.load!(".yardoc")
    files_target = "guides/yardoc"
    FileUtils.rm_rf(files_target)
    FileUtils.mkdir_p(files_target)

    # Get docs for all classes and modules
    docs = registry.all(:class, :module)
    docs.each do |code_object|
      begin
        # Skip private classes and modules
        if code_object.visibility == :private
          next
        end
        rubydoc_url = to_rubydoc_url(code_object.path)
        page_content = DOC_TEMPLATE % {
          title: code_object.path,
          url: rubydoc_url,
          documentation: code_object.format.gsub(/-{2,}/, " ").gsub(/^\s+/, ""),
        }

        filename = code_object.path.gsub(/\W+/, "_")
        filepath = "guides/yardoc/#{filename}.md"
        File.write(filepath, page_content)
      rescue StandardError => err
        puts "Error on: #{code_object.path}"
        puts err
        puts err.backtrace
      end
    end
    puts "Wrote #{docs.size} YARD docs to #{files_target}."
  end

  desc "Update the Algolia search index used for graphql-ruby.org"
  task :update_search_index do
    if !ENV["ALGOLIA_API_KEY"]
      warn("Can't update search index without ALGOLIA_API_KEY; Search will be out-of-date.")
    else
      system("bundle exec jekyll algolia push --source=./guides")
    end
  end
end
