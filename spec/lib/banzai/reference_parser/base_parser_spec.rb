# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::ReferenceParser::BaseParser do
  include ReferenceParserHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:context) { Banzai::RenderContext.new(project, user) }
  let(:parser_class) do
    Class.new(described_class) do
      self.reference_type = :foo
    end
  end

  subject do
    parser_class.new(context)
  end

  describe '.reference_type=' do
    it 'sets the reference type' do
      dummy = Class.new(described_class)
      dummy.reference_type = :foo

      expect(dummy.reference_type).to eq(:foo)
    end
  end

  describe '#project_for_node' do
    it 'returns the Project for a node' do
      document = instance_double('document', fragment?: false)
      project = instance_double('project')
      object = instance_double('object', project: project)
      node = instance_double('node', document: document)

      context.associate_document(document, object)

      expect(subject.project_for_node(node)).to eq(project)
    end
  end

  describe '#nodes_visible_to_user' do
    let(:link) { empty_html_link }

    context 'when the link has a data-project attribute' do
      before do
        link['data-project'] = project.id.to_s
      end

      it 'includes the link if can_read_reference? returns true' do
        expect(subject).to receive(:can_read_reference?).with(user, project, link).and_return(true)

        expect(subject.nodes_visible_to_user(user, [link])).to contain_exactly(link)
      end

      it 'excludes the link if can_read_reference? returns false' do
        expect(subject).to receive(:can_read_reference?).with(user, project, link).and_return(false)

        expect(subject.nodes_visible_to_user(user, [link])).to be_empty
      end
    end

    context 'when the link does not have a data-project attribute' do
      it 'returns the nodes' do
        expect(subject.nodes_visible_to_user(user, [link])).to eq([link])
      end
    end
  end

  describe '#nodes_user_can_reference' do
    it 'returns the nodes' do
      link = double(:link)

      expect(subject.nodes_user_can_reference(user, [link])).to eq([link])
    end
  end

  describe '#referenced_by' do
    context 'when references_relation is implemented' do
      context 'and ids_only is set to false' do
        it 'returns a collection of objects' do
          links = Nokogiri::HTML.fragment("<a data-foo='#{user.id}'></a>")
                    .children

          expect(subject).to receive(:references_relation).and_return(User)
          expect(subject.referenced_by(links)).to eq([user])
        end
      end

      context 'and ids_only is set to true' do
        it 'returns a collection of id values without performing a db query' do
          links = Nokogiri::HTML.fragment("<a data-foo='1'></a><a data-foo='2'></a>").children

          expect(subject).not_to receive(:references_relation)
          expect(subject.referenced_by(links, ids_only: true)).to eq(%w(1 2))
        end

        context 'and the html fragment does not contain any attributes' do
          it 'returns an empty array' do
            links = Nokogiri::HTML.fragment("no links").children

            expect(subject.referenced_by(links, ids_only: true)).to eq([])
          end
        end
      end
    end

    context 'when references_relation is not implemented' do
      it 'raises NotImplementedError' do
        links = Nokogiri::HTML.fragment('<a data-foo="1"></a>').children

        expect { subject.referenced_by(links) }
          .to raise_error(NotImplementedError)
      end
    end
  end

  describe '#references_relation' do
    it 'raises NotImplementedError' do
      expect { subject.references_relation }.to raise_error(NotImplementedError)
    end
  end

  describe '#gather_attributes_per_project' do
    it 'returns a Hash containing attribute values per project' do
      link = Nokogiri::HTML.fragment('<a data-project="1" data-foo="2"></a>')
        .children[0]

      hash = subject.gather_attributes_per_project([link], 'data-foo')

      expect(hash).to be_an_instance_of(Hash)

      expect(hash[1].to_a).to eq(['2'])
    end
  end

  describe '#grouped_objects_for_nodes' do
    it 'returns a Hash grouping objects per node' do
      link = double(:link)

      expect(link).to receive(:has_attribute?)
        .with('data-user')
        .and_return(true)

      expect(link).to receive(:attr)
        .with('data-user')
        .and_return(user.id.to_s)

      nodes = [link]

      expect(subject).to receive(:unique_attribute_values)
        .with(nodes, 'data-user')
        .and_return([user.id.to_s])

      hash = subject.grouped_objects_for_nodes(nodes, User, 'data-user')

      expect(hash).to eq({ link => user })
    end

    it 'returns an empty Hash when entry does not exist in the database', :request_store do
      link = double(:link)

      expect(link).to receive(:has_attribute?)
          .with('data-user')
          .and_return(true)

      expect(link).to receive(:attr)
          .with('data-user')
          .and_return('1')

      nodes = [link]
      bad_id = user.id + 100

      expect(subject).to receive(:unique_attribute_values)
          .with(nodes, 'data-user')
          .and_return([bad_id.to_s])

      hash = subject.grouped_objects_for_nodes(nodes, User, 'data-user')

      expect(hash).to eq({})
    end
  end

  describe '#unique_attribute_values' do
    it 'returns an Array of unique values' do
      link = double(:link)

      expect(link).to receive(:has_attribute?)
        .with('data-foo')
        .twice
        .and_return(true)

      expect(link).to receive(:attr)
        .with('data-foo')
        .twice
        .and_return('1')

      nodes = [link, link]

      expect(subject.unique_attribute_values(nodes, 'data-foo')).to eq(['1'])
    end
  end

  describe '#process' do
    it 'gathers the references for every node matching the reference type' do
      dummy = Class.new(described_class) do
        self.reference_type = :test

        def gather_references(nodes, ids_only: false)
          nodes
        end
      end

      instance = dummy.new(context)
      document_a = Nokogiri::HTML.fragment(<<-FRAG)
      <a class="gfm">one</a>
      <a class="gfm" data-reference-type="test">two</a>
      <a class="gfm" data-reference-type="other">three</a>
      FRAG
      document_b = Nokogiri::HTML.fragment(<<-FRAG)
      <a class="gfm" data-reference-type="test">four</a>
      FRAG
      document_c = Nokogiri::HTML.fragment('')

      expect(instance.process([document_a, document_b, document_c]))
        .to contain_exactly(document_a.css('a')[1], document_b.css('a')[0])
    end
  end

  describe '#gather_references' do
    let(:nodes) { (1..10).map { |n| double(:link, id: n) } }

    let(:parser_class) do
      Class.new(described_class) do
        def nodes_user_can_reference(_user, nodes)
          nodes.select { |n| n.id.even? }
        end

        def nodes_visible_to_user(_user, nodes)
          nodes.select { |n| n.id > 5 }
        end

        def referenced_by(nodes, ids_only: false)
          nodes.map(&:id)
        end
      end
    end

    it 'returns referenceable and visible objects, alongside nodes that are referenceable but not visible' do
      expect(subject.gather_references(nodes)).to match(
        visible: contain_exactly(6, 8, 10),
        not_visible: match_array(nodes.select { |n| n.id.even? && n.id <= 5 })
      )
    end

    it 'is always empty if the input is empty' do
      expect(subject.gather_references([])) .to match(visible: be_empty, not_visible: be_empty)
    end
  end

  describe '#can?' do
    it 'delegates the permissions check to the Ability class' do
      user = double(:user)

      expect(Ability).to receive(:allowed?)
        .with(user, :read_project, project)

      subject.can?(user, :read_project, project)
    end
  end

  describe '#find_projects_for_hash_keys' do
    it 'returns a list of Projects' do
      expect(subject.find_projects_for_hash_keys(project.id => project))
        .to eq([project])
    end
  end

  describe '#collection_objects_for_ids' do
    context 'with RequestStore disabled' do
      it 'queries the collection directly' do
        collection = User.all

        expect(collection).to receive(:where).twice.and_call_original

        2.times do
          expect(subject.collection_objects_for_ids(collection, [user.id]))
            .to eq([user])
        end
      end
    end

    context 'with RequestStore enabled', :request_store do
      before do
        cache = Hash.new { |hash, key| hash[key] = {} }

        allow(subject).to receive(:collection_cache).and_return(cache)
      end

      it 'queries the collection on the first call' do
        expect(subject.collection_objects_for_ids(User, [user.id]))
          .to eq([user])
      end

      it 'does not query previously queried objects' do
        collection = User.all

        expect(collection).to receive(:where).once.and_call_original

        2.times do
          expect(subject.collection_objects_for_ids(collection, [user.id]))
            .to eq([user])
        end
      end

      it 'casts String based IDs to Fixnums before querying objects' do
        2.times do
          expect(subject.collection_objects_for_ids(User, [user.id.to_s]))
            .to eq([user])
        end
      end

      it 'queries any additional objects after the first call' do
        other_user = create(:user)

        expect(subject.collection_objects_for_ids(User, [user.id]))
          .to eq([user])

        expect(subject.collection_objects_for_ids(User, [user.id, other_user.id]))
          .to eq([user, other_user])
      end

      it 'caches objects on a per collection class basis' do
        expect(subject.collection_objects_for_ids(User, [user.id]))
          .to eq([user])

        expect(subject.collection_objects_for_ids(Project, [project.id]))
          .to eq([project])
      end

      it 'will not overflow the stack' do
        ids = 1.upto(1_000_000).to_a

        # Avoid executing a large, unnecessary SQL query
        expect(User).to receive(:where).with(id: ids).and_return(User.none)

        expect { subject.collection_objects_for_ids(User, ids) }.not_to raise_error
      end
    end
  end

  describe '#collection_cache_key' do
    it 'returns the cache key for a Class' do
      expect(subject.collection_cache_key(Project)).to eq(Project)
    end

    it 'returns the cache key for an ActiveRecord::Relation' do
      expect(subject.collection_cache_key(Project.all)).to eq(Project)
    end
  end
end
