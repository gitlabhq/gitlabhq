# frozen_string_literal: true

require 'spec_helper'

describe Banzai::ReferenceParser::BaseParser do
  include ReferenceParserHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:context) { Banzai::RenderContext.new(project, user) }

  subject do
    klass = Class.new(described_class) do
      self.reference_type = :foo
    end

    klass.new(context)
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
      it 'checks if user can read the resource' do
        link['data-project'] = project.id.to_s

        expect(subject).to receive(:can_read_reference?).with(user, project, link)

        subject.nodes_visible_to_user(user, [link])
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
      it 'returns a collection of objects' do
        links = Nokogiri::HTML.fragment("<a data-foo='#{user.id}'></a>")
          .children

        expect(subject).to receive(:references_relation).and_return(User)
        expect(subject.referenced_by(links)).to eq([user])
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
      end

      instance = dummy.new(Banzai::RenderContext.new(project, user))
      document = Nokogiri::HTML.fragment('<a class="gfm"></a><a class="gfm" data-reference-type="test"></a>')

      expect(instance).to receive(:gather_references)
        .with([document.children[1]])
        .and_return([user])

      expect(instance.process([document])).to eq([user])
    end
  end

  describe '#gather_references' do
    let(:link) { double(:link) }

    it 'does not process links a user can not reference' do
      expect(subject).to receive(:nodes_user_can_reference)
        .with(user, [link])
        .and_return([])

      expect(subject).to receive(:referenced_by).with([])

      subject.gather_references([link])
    end

    it 'does not process links a user can not see' do
      expect(subject).to receive(:nodes_user_can_reference)
        .with(user, [link])
        .and_return([link])

      expect(subject).to receive(:nodes_visible_to_user)
        .with(user, [link])
        .and_return([])

      expect(subject).to receive(:referenced_by).with([])

      subject.gather_references([link])
    end

    it 'returns the references if a user can reference and see a link' do
      expect(subject).to receive(:nodes_user_can_reference)
        .with(user, [link])
        .and_return([link])

      expect(subject).to receive(:nodes_visible_to_user)
        .with(user, [link])
        .and_return([link])

      expect(subject).to receive(:referenced_by).with([link])

      subject.gather_references([link])
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
