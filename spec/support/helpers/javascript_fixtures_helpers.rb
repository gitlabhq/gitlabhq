require 'action_dispatch/testing/test_request'
require 'fileutils'

module JavaScriptFixturesHelpers
  include Gitlab::Popen

  FIXTURE_PATHS = %w[spec/javascripts/fixtures ee/spec/javascripts/fixtures].freeze

  # Public: Removes all fixture files from given directory
  #
  # directory_name - directory of the fixtures (relative to FIXTURE_PATHS)
  #
  def clean_frontend_fixtures(directory_name)
    FIXTURE_PATHS.each do |fixture_path|
      directory_name = File.expand_path(directory_name, fixture_path)
      Dir[File.expand_path('*.html.raw', directory_name)].each do |file_name|
        FileUtils.rm(file_name)
      end
    end
  end

  # Public: Store a response object as fixture file
  #
  # response - string or response object to store
  # fixture_file_name - file name to store the fixture in (relative to FIXTURE_PATHS)
  #
  def store_frontend_fixture(response, fixture_file_name)
    FIXTURE_PATHS.each do |fixture_path|
      fixture_file_name = File.expand_path(fixture_file_name, fixture_path)
      fixture = response.respond_to?(:body) ? parse_response(response) : response

      FileUtils.mkdir_p(File.dirname(fixture_file_name))
      File.write(fixture_file_name, fixture)
    end
  end

  def remove_repository(project)
    Gitlab::Shell.new.remove_repository(project.repository_storage, project.disk_path)
  end

  private

  # Private: Prepare a response object for use as a frontend fixture
  #
  # response - response object to prepare
  #
  def parse_response(response)
    fixture = response.body
    fixture.force_encoding("utf-8")

    response_mime_type = Mime::Type.lookup(response.content_type)
    if response_mime_type.html?
      doc = Nokogiri::HTML::DocumentFragment.parse(fixture)

      link_tags = doc.css('link')
      link_tags.remove

      scripts = doc.css("script:not([type='text/template']):not([type='text/x-template'])")
      scripts.remove

      fixture = doc.to_html

      # replace relative links
      test_host = ActionDispatch::TestRequest::DEFAULT_ENV['HTTP_HOST']
      fixture.gsub!(%r{="/}, "=\"http://#{test_host}/")
    end

    fixture
  end
end
