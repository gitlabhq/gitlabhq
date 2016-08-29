require 'fileutils'
require 'gitlab/popen'

module JavaScriptFixturesHelpers
  include Gitlab::Popen

  FIXTURE_PATH = 'spec/javascripts/fixtures'

  # Public: Removes all fixture files from given directory
  #
  # directory_name - directory of the fixtures (relative to FIXTURE_PATH)
  #
  def clean_frontend_fixtures(directory_name)
    directory_name = File.expand_path(directory_name, FIXTURE_PATH)
    Dir[File.expand_path('*.html.raw', directory_name)].each do |file_name|
      FileUtils.rm(file_name)
    end
  end

  # Public: Store a response object as fixture file
  #
  # response - response object to store
  # fixture_file_name - file name to store the fixture in (relative to FIXTURE_PATH)
  #
  def store_frontend_fixture(response, fixture_file_name)
    fixture_file_name = File.expand_path(fixture_file_name, FIXTURE_PATH)
    fixture = response.body

    response_mime_type = Mime::Type.lookup(response.content_type)
    if response_mime_type.html?
      doc = Nokogiri::HTML::DocumentFragment.parse(fixture)

      scripts = doc.css('script')
      scripts.remove

      fixture = doc.to_html

      # replace relative links
      fixture.gsub!(%r{="/}, '="https://fixture.invalid/')
    end

    FileUtils.mkdir_p(File.dirname(fixture_file_name))
    File.write(fixture_file_name, fixture)
  end
end
