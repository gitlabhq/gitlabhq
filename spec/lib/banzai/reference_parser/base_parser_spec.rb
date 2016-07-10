require 'spec_helper'

describe Banzai::ReferenceParser::BaseParser, lib: true do
  include ReferenceParserHelpers

  let(:user) { create(:user) }
  let(:project) { create(:empty_project, :public) }

  subject do
    klass = Class.new(described_class) do
      self.reference_type = :foo
    end

    klass.new(project, user)
  end

  describe '.reference_type=' do
    it 'sets the reference type' do
      dummy = Class.new(described_class)
      dummy.reference_type = :foo

      expect(dummy.reference_type).to eq(:foo)
    end
  end

  describe '#nodes_visible_to_user' do
    let(:link) { empty_html_link }

    context 'when the link has a data-project attribute' do
      it 'returns the nodes if the attribute value equals the current project ID' do
        link['data-project'] = project.id.to_s

        expect(Ability.abilities).not_to receive(:allowed?)
        expect(subject.nodes_visible_to_user(user, [link])).to eq([link])
      end

      it 'returns the nodes if the user can read the project' do
        other_project = create(:empty_project, :public)

        link['data-project'] = other_project.id.to_s

        expect(Ability.abilities).to receive(:allowed?).
          with(user, :read_project, other_project).
          and_return(true)

        expect(subject.nodes_visible_to_user(user, [link])).to eq([link])
      end

      it 'returns an empty Array when the attribute value is empty' do
        link['data-project'] = ''

        expect(subject.nodes_visible_to_user(user, [link])).to eq([])
      end

      it 'returns an empty Array when the user can not read the project' do
        other_project = create(:empty_project, :public)

        link['data-project'] = other_project.id.to_s

        expect(Ability.abilities).to receive(:allowed?).
          with(user, :read_project, other_project).
          and_return(false)

        expect(subject.nodes_visible_to_user(user, [link])).to eq([])
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
        links = Nokogiri::HTML.fragment("<a data-foo='#{user.id}'></a>").
          children

        expect(subject).to receive(:references_relation).and_return(User)
        expect(subject.referenced_by(links)).to eq([user])
      end
    end

    context 'when references_relation is not implemented' do
      it 'raises NotImplementedError' do
        links = Nokogiri::HTML.fragment('<a data-foo="1"></a>').children

        expect { subject.referenced_by(links) }.
          to raise_error(NotImplementedError)
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
      link = Nokogiri::HTML.fragment('<a data-project="1" data-foo="2"></a>').
        children[0]

      hash = subject.gather_attributes_per_project([link], 'data-foo')

      expect(hash).to be_an_instance_of(Hash)

      expect(hash[1].to_a).to eq(['2'])
    end
  end

  describe '#grouped_objects_for_nodes' do
    it 'returns a Hash grouping objects per ID' do
      nodes = [double(:node)]

      expect(subject).to receive(:unique_attribute_values).
        with(nodes, 'data-user').
        and_return([user.id])

      hash = subject.grouped_objects_for_nodes(nodes, User, 'data-user')

      expect(hash).to eq({ user.id => user })
    end

    it 'returns an empty Hash when the list of nodes is empty' do
      expect(subject.grouped_objects_for_nodes([], User, 'data-user')).to eq({})
    end
  end

  describe '#unique_attribute_values' do
    it 'returns an Array of unique values' do
      link = double(:link)

      expect(link).to receive(:has_attribute?).
        with('data-foo').
        twice.
        and_return(true)

      expect(link).to receive(:attr).
        with('data-foo').
        twice.
        and_return('1')

      nodes = [link, link]

      expect(subject.unique_attribute_values(nodes, 'data-foo')).to eq(['1'])
    end
  end

  describe '#process' do
    it 'gathers the references for every node matching the reference type' do
      dummy = Class.new(described_class) do
        self.reference_type = :test
      end

      instance = dummy.new(project, user)
      document = Nokogiri::HTML.fragment('<a class="gfm"></a><a class="gfm" data-reference-type="test"></a>')

      expect(instance).to receive(:gather_references).
        with([document.children[1]]).
        and_return([user])

      expect(instance.process([document])).to eq([user])
    end
  end

  describe '#gather_references' do
    let(:link) { double(:link) }

    it 'does not process links a user can not reference' do
      expect(subject).to receive(:nodes_user_can_reference).
        with(user, [link]).
        and_return([])

      expect(subject).to receive(:referenced_by).with([])

      subject.gather_references([link])
    end

    it 'does not process links a user can not see' do
      expect(subject).to receive(:nodes_user_can_reference).
        with(user, [link]).
        and_return([link])

      expect(subject).to receive(:nodes_visible_to_user).
        with(user, [link]).
        and_return([])

      expect(subject).to receive(:referenced_by).with([])

      subject.gather_references([link])
    end

    it 'returns the references if a user can reference and see a link' do
      expect(subject).to receive(:nodes_user_can_reference).
        with(user, [link]).
        and_return([link])

      expect(subject).to receive(:nodes_visible_to_user).
        with(user, [link]).
        and_return([link])

      expect(subject).to receive(:referenced_by).with([link])

      subject.gather_references([link])
    end
  end

  describe '#can?' do
    it 'delegates the permissions check to the Ability class' do
      user = double(:user)

      expect(Ability.abilities).to receive(:allowed?).
        with(user, :read_project, project)

      subject.can?(user, :read_project, project)
    end
  end

  describe '#find_projects_for_hash_keys' do
    it 'returns a list of Projects' do
      expect(subject.find_projects_for_hash_keys(project.id => project)).
        to eq([project])
    end
  end

  describe '#collection_objects_for_ids' do
    context 'with RequestStore disabled' do
      it 'queries the collection directly' do
        collection = User.all

        expect(collection).to receive(:where).twice.and_call_original

        2.times do
          expect(subject.collection_objects_for_ids(collection, [user.id])).
            to eq([user])
        end
      end
    end

    context 'with RequestStore enabled' do
      before do
        cache = Hash.new { |hash, key| hash[key] = {} }

        allow(RequestStore).to receive(:active?).and_return(true)
        allow(subject).to receive(:collection_cache).and_return(cache)
      end

      it 'queries the collection on the first call' do
        expect(subject.collection_objects_for_ids(User, [user.id])).
          to eq([user])
      end

      it 'does not query previously queried objects' do
        collection = User.all

        expect(collection).to receive(:where).once.and_call_original

        2.times do
          expect(subject.collection_objects_for_ids(collection, [user.id])).
            to eq([user])
        end
      end

      it 'casts String based IDs to Fixnums before querying objects' do
        2.times do
          expect(subject.collection_objects_for_ids(User, [user.id.to_s])).
            to eq([user])
        end
      end

      it 'queries any additional objects after the first call' do
        other_user = create(:user)

        expect(subject.collection_objects_for_ids(User, [user.id])).
          to eq([user])

        expect(subject.collection_objects_for_ids(User, [user.id, other_user.id])).
          to eq([user, other_user])
      end

      it 'caches objects on a per collection class basis' do
        expect(subject.collection_objects_for_ids(User, [user.id])).
          to eq([user])

        expect(subject.collection_objects_for_ids(Project, [project.id])).
          to eq([project])
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
