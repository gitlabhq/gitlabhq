# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'parser/current'
require_relative '../../rubocop/code_reuse_helpers'

RSpec.describe RuboCop::CodeReuseHelpers do
  def build_and_parse_source(source, path = 'foo.rb')
    buffer = Parser::Source::Buffer.new(path)
    buffer.source = source

    builder = RuboCop::AST::Builder.new
    parser = Parser::CurrentRuby.new(builder)

    parser.parse(buffer)
  end

  let(:cop) do
    Class.new do
      include RuboCop::CodeReuseHelpers
    end.new
  end

  let(:ee_file_path) { File.expand_path('../../ee/app/models/license.rb', __dir__) }

  describe '#send_to_constant?' do
    it 'returns true when sending to a constant' do
      node = build_and_parse_source('Foo.bar')

      expect(cop.send_to_constant?(node)).to eq(true)
    end

    it 'returns false when sending to something other than a constant' do
      node = build_and_parse_source('10')

      expect(cop.send_to_constant?(node)).to eq(false)
    end
  end

  describe '#send_receiver_name_ends_with?' do
    it 'returns true when the receiver ends with a suffix' do
      node = build_and_parse_source('FooFinder.new')

      expect(cop.send_receiver_name_ends_with?(node, 'Finder')).to eq(true)
    end

    it 'returns false when the receiver is the same as a suffix' do
      node = build_and_parse_source('Finder.new')

      expect(cop.send_receiver_name_ends_with?(node, 'Finder')).to eq(false)
    end
  end

  describe '#file_path_for_node' do
    it 'returns the file path of a node' do
      node = build_and_parse_source('10')
      path = cop.file_path_for_node(node)

      expect(path).to eq('foo.rb')
    end
  end

  describe '#name_of_constant' do
    it 'returns the name of a constant' do
      node = build_and_parse_source('Foo')

      expect(cop.name_of_constant(node)).to eq(:Foo)
    end
  end

  describe '#in_finder?' do
    it 'returns true for a node in the finders directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'finders', 'foo.rb'))

      expect(cop.in_finder?(node)).to eq(true)
    end

    it 'returns false for a node outside the finders directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'foo', 'foo.rb'))

      expect(cop.in_finder?(node)).to eq(false)
    end
  end

  describe '#in_model?' do
    it 'returns true for a node in the models directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'models', 'foo.rb'))

      expect(cop.in_model?(node)).to eq(true)
    end

    it 'returns false for a node outside the models directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'foo', 'foo.rb'))

      expect(cop.in_model?(node)).to eq(false)
    end
  end

  describe '#in_service_class?' do
    it 'returns true for a node in the services directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'services', 'foo.rb'))

      expect(cop.in_service_class?(node)).to eq(true)
    end

    it 'returns false for a node outside the services directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'foo', 'foo.rb'))

      expect(cop.in_service_class?(node)).to eq(false)
    end
  end

  describe '#in_presenter?' do
    it 'returns true for a node in the presenters directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'presenters', 'foo.rb'))

      expect(cop.in_presenter?(node)).to eq(true)
    end

    it 'returns false for a node outside the presenters directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'foo', 'foo.rb'))

      expect(cop.in_presenter?(node)).to eq(false)
    end
  end

  describe '#in_serializer?' do
    it 'returns true for a node in the serializers directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'serializers', 'foo.rb'))

      expect(cop.in_serializer?(node)).to eq(true)
    end

    it 'returns false for a node outside the serializers directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'foo', 'foo.rb'))

      expect(cop.in_serializer?(node)).to eq(false)
    end
  end

  describe '#in_worker?' do
    it 'returns true for a node in the workers directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'workers', 'foo.rb'))

      expect(cop.in_worker?(node)).to eq(true)
    end

    it 'returns false for a node outside the workers directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'foo', 'foo.rb'))

      expect(cop.in_worker?(node)).to eq(false)
    end
  end

  describe '#in_graphql?' do
    it 'returns true for a node in the FOSS GraphQL directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'graphql', 'foo.rb'))

      expect(cop.in_graphql?(node)).to eq(true)
    end

    it 'returns true for a node in the EE GraphQL directory' do
      node = build_and_parse_source('10', rails_root_join('ee', 'app', 'graphql', 'foo.rb'))

      expect(cop.in_graphql?(node)).to eq(true)
    end

    it 'returns false for a node outside the GraphQL directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'foo', 'foo.rb'))

      expect(cop.in_graphql?(node)).to eq(false)
    end
  end

  describe '#in_api?' do
    it 'returns true for a node in the API directory' do
      node = build_and_parse_source('10', rails_root_join('lib', 'api', 'foo.rb'))

      expect(cop.in_api?(node)).to eq(true)
    end

    it 'returns false for a node outside the API directory' do
      node = build_and_parse_source('10', rails_root_join('lib', 'foo', 'foo.rb'))

      expect(cop.in_api?(node)).to eq(false)
    end
  end

  describe '#in_spec?' do
    it 'returns true for a node in the spec directory' do
      node = build_and_parse_source('10', rails_root_join('spec', 'foo.rb'))

      expect(cop.in_spec?(node)).to eq(true)
    end

    it 'returns true for a node in the ee/spec directory' do
      node = build_and_parse_source('10', rails_root_join('ee', 'spec', 'foo.rb'))

      expect(cop.in_spec?(node)).to eq(true)
    end

    it 'returns false for a node outside the spec directory' do
      node = build_and_parse_source('10', rails_root_join('lib', 'foo.rb'))

      expect(cop.in_spec?(node)).to eq(false)
    end
  end

  describe '#in_app_directory?' do
    it 'returns true for a directory in the CE app/ directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'models', 'foo.rb'))

      expect(cop.in_app_directory?(node, 'models')).to eq(true)
    end

    it 'returns true for a directory in the EE app/ directory' do
      node =
        build_and_parse_source('10', rails_root_join('ee', 'app', 'models', 'foo.rb'))

      expect(cop.in_app_directory?(node, 'models')).to eq(true)
    end

    it 'returns false for a directory in the lib/ directory' do
      node =
        build_and_parse_source('10', rails_root_join('lib', 'models', 'foo.rb'))

      expect(cop.in_app_directory?(node, 'models')).to eq(false)
    end
  end

  describe '#in_lib_directory?' do
    it 'returns true for a directory in the CE lib/ directory' do
      node = build_and_parse_source('10', rails_root_join('lib', 'models', 'foo.rb'))

      expect(cop.in_lib_directory?(node, 'models')).to eq(true)
    end

    it 'returns true for a directory in the EE lib/ directory' do
      node =
        build_and_parse_source('10', rails_root_join('ee', 'lib', 'models', 'foo.rb'))

      expect(cop.in_lib_directory?(node, 'models')).to eq(true)
    end

    it 'returns false for a directory in the app/ directory' do
      node =
        build_and_parse_source('10', rails_root_join('app', 'models', 'foo.rb'))

      expect(cop.in_lib_directory?(node, 'models')).to eq(false)
    end
  end

  describe '#in_graphql_directory?' do
    it 'returns true for a directory in the FOSS app/graphql directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'graphql', 'subdir', 'foo.rb'))

      expect(cop.in_graphql_directory?(node, 'subdir')).to eq(true)
    end

    it 'returns true for a directory in the EE app/graphql directory' do
      node = build_and_parse_source('10', rails_root_join('ee', 'app', 'graphql', 'subdir', 'foo.rb'))

      expect(cop.in_graphql_directory?(node, 'subdir')).to eq(true)
    end

    it 'returns true for a directory in the EE app/graphql/ee directory' do
      node = build_and_parse_source('10', rails_root_join('ee', 'app', 'graphql', 'ee', 'subdir', 'foo.rb'))

      expect(cop.in_graphql_directory?(node, 'subdir')).to eq(true)
    end

    it 'returns false for a directory in the FOSS app/graphql directory' do
      node = build_and_parse_source('10', rails_root_join('app', 'graphql', 'anotherdir', 'foo.rb'))

      expect(cop.in_graphql_directory?(node, 'subdir')).to eq(false)
    end

    it 'returns false for a directory in the EE app/graphql directory' do
      node = build_and_parse_source('10', rails_root_join('ee', 'app', 'graphql', 'anotherdir', 'foo.rb'))

      expect(cop.in_graphql_directory?(node, 'subdir')).to eq(false)
    end

    it 'returns false for a directory in the EE app/graphql/ee directory' do
      node = build_and_parse_source('10', rails_root_join('ee', 'app', 'graphql', 'ee', 'anotherdir', 'foo.rb'))

      expect(cop.in_graphql_directory?(node, 'subdir')).to eq(false)
    end
  end

  describe '#name_of_receiver' do
    it 'returns the name of a send receiver' do
      node = build_and_parse_source('Foo.bar')

      expect(cop.name_of_receiver(node)).to eq('Foo')
    end
  end

  describe '#each_class_method' do
    it 'yields every class method to the supplied block' do
      node = build_and_parse_source(<<~RUBY)
        class Foo
          class << self
            def first
            end
          end

          def self.second
          end
        end
      RUBY

      nodes = cop.each_class_method(node).to_a

      expect(nodes.length).to eq(2)

      expect(nodes[0].children[0]).to eq(:first)
      expect(nodes[1].children[1]).to eq(:second)
    end
  end

  describe '#each_send_node' do
    it 'yields every send node to the supplied block' do
      node = build_and_parse_source("foo\nbar")
      nodes = cop.each_send_node(node).to_a

      expect(nodes.length).to eq(2)
      expect(nodes[0].children[1]).to eq(:foo)
      expect(nodes[1].children[1]).to eq(:bar)
    end
  end

  describe '#disallow_send_to' do
    it 'disallows sending a message to a constant' do
      def_node = build_and_parse_source(<<~RUBY)
        def foo
          FooFinder.new
        end
      RUBY

      send_node = def_node.each_child_node(:send).first

      expect(cop)
        .to receive(:add_offense)
        .with(send_node, message: 'oops')

      cop.disallow_send_to(def_node, 'Finder', 'oops')
    end
  end

  %w[ee? jh?].each do |method_name|
    it "delegates #{method_name} to GitlabEdition" do
      expect(GitlabEdition).to receive(method_name)

      cop.public_send(method_name)
    end
  end
end
