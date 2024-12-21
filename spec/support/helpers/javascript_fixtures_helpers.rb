# frozen_string_literal: true

require 'action_dispatch/testing/test_request'
require 'fileutils'
require 'graphlyte'
require 'active_support/testing/time_helpers'

require_relative '../../../lib/gitlab/popen'

module JavaScriptFixturesHelpers
  extend ActiveSupport::Concern
  include Gitlab::Popen
  include ActiveSupport::Testing::TimeHelpers

  extend self

  included do |base|
    base.around do |example|
      # Don't actually run the example when we're only interested in the `test file -> JSON frontend fixture` mapping
      if ENV['GENERATE_FRONTEND_FIXTURES_MAPPING'] == 'true'
        $fixtures_mapping[example.metadata[:file_path].delete_prefix('./')] << File.join(fixture_root_path, example.description) # rubocop:disable Style/GlobalVars
        next
      end

      # pick an arbitrary date from the past, so tests are not time dependent
      # Also see spec/frontend/__helpers__/fake_date/jest.js
      travel_to Time.utc(2015, 7, 3, 10)
      example.run
      travel_back

      raise NoMethodError.new('You need to set `response` for the fixture generator! This will automatically happen with `type: :controller` or `type: :request`.', 'response') unless respond_to?(:response)

      store_frontend_fixture(response, example.description)
    end
  end

  def fixture_root_path
    'tmp/tests/frontend/fixtures' + (Gitlab.ee? ? '-ee' : '')
  end

  def remove_repository(project)
    project.repository.remove
  end

  # Public: Reads a GraphQL query from the filesystem as a string
  #
  # query_path - file path to the GraphQL query, relative to `app/assets/javascripts`.
  # ee - boolean, when true `query_path` will be looked up in `/ee`.
  def get_graphql_query_as_string(query_path, ee: false, with_base_path: true)
    base = (ee ? 'ee/' : '') + (with_base_path ? 'app/assets/javascripts' : '')
    path = Rails.root / base / query_path
    queries = Gitlab::Graphql::Queries.find(path)
    if queries.length == 1
      query = queries.first.text(mode: Gitlab.ee? ? :ee : :ce)
      inflate_query_with_typenames(query)
    else
      raise "Could not find query file at #{path}, please check your query_path" % path
    end
  end

  private

  # Private: Parse a GraphQL query and inflate the fields with a __typename
  #
  # query - the GraqhQL query to parse
  def inflate_query_with_typenames(query, doc: Graphlyte.parse(query))
    typename_editor.edit(doc)

    doc.to_s
  end

  def typename_editor
    typename = Graphlyte::Syntax::Field.new(name: '__typename')

    @editor ||= Graphlyte::Editor.new.on_field do |field|
      is_typename = field.selection.respond_to?(:name) && field.selection.map(&:name).include?('__typename')
      field.selection << typename unless field.selection.empty? || is_typename
    end
  end

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
