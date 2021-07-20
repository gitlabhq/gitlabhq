# frozen_string_literal: true

require 'action_dispatch/testing/test_request'
require 'fileutils'

module JavaScriptFixturesHelpers
  extend ActiveSupport::Concern
  include Gitlab::Popen

  extend self

  included do |base|
    base.around do |example|
      # pick an arbitrary date from the past, so tests are not time dependent
      # Also see spec/frontend/__helpers__/fake_date/jest.js
      Timecop.freeze(Time.utc(2015, 7, 3, 10)) { example.run }

      raise NoMethodError.new('You need to set `response` for the fixture generator! This will automatically happen with `type: :controller` or `type: :request`.', 'response') unless respond_to?(:response)

      store_frontend_fixture(response, example.description)
    end
  end

  def fixture_root_path
    'tmp/tests/frontend/fixtures' + (Gitlab.ee? ? '-ee' : '')
  end

  # Public: Removes all fixture files from given directory
  #
  # directory_name - directory of the fixtures (relative to .fixture_root_path)
  #
  def clean_frontend_fixtures(directory_name)
    full_directory_name = File.expand_path(directory_name, fixture_root_path)
    Dir[File.expand_path('*.{html,json,md}', full_directory_name)].each do |file_name|
      FileUtils.rm(file_name)
    end
  end

  def remove_repository(project)
    Gitlab::Shell.new.remove_repository(project.repository_storage, project.disk_path)
  end

  # Public: Reads a GraphQL query from the filesystem as a string
  #
  # query_path - file path to the GraphQL query, relative to `app/assets/javascripts`
  def get_graphql_query_as_string(query_path)
    path = Rails.root / 'app/assets/javascripts' / query_path
    queries = Gitlab::Graphql::Queries.find(path)
    if queries.length == 1
      queries.first.text(mode: Gitlab.ee? ? :ee : :ce )
    else
      raise "Could not find query file at #{path}, please check your query_path" % path
    end
  end

  private

  # Private: Store a response object as fixture file
  #
  # response - string or response object to store
  # fixture_file_name - file name to store the fixture in (relative to .fixture_root_path)
  #
  def store_frontend_fixture(response, fixture_file_name)
    full_fixture_path = File.expand_path(fixture_file_name, fixture_root_path)
    fixture = response.respond_to?(:body) ? parse_response(response) : response

    FileUtils.mkdir_p(File.dirname(full_fixture_path))
    File.write(full_fixture_path, fixture)
  end

  def parse_html(fixture)
    if respond_to?(:use_full_html) && public_send(:use_full_html)
      Nokogiri::HTML::Document.parse(fixture)
    else
      Nokogiri::HTML::DocumentFragment.parse(fixture)
    end
  end

  # Private: Prepare a response object for use as a frontend fixture
  #
  # response - response object to prepare
  #
  def parse_response(response)
    fixture = response.body
    fixture.force_encoding("utf-8")

    response_mime_type = Mime::Type.lookup(response.media_type)
    if response_mime_type.html?
      doc = parse_html(fixture)

      link_tags = doc.css('link')
      link_tags.remove

      scripts = doc.css("script:not([type='text/template']):not([type='text/x-template']):not([type='application/json'])")
      scripts.remove

      fixture = doc.to_html

      # replace relative links
      test_host = ActionDispatch::TestRequest::DEFAULT_ENV['HTTP_HOST']
      fixture.gsub!(%r{="/}, "=\"http://#{test_host}/")
    end

    fixture
  end
end
