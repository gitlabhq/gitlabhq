require 'spec_helper'

describe Banzai::ReferenceParser::Parser, lib: true do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project, :public) }
  let(:parser) { described_class.new(project, user, user) }

  describe '.reference_type=' do
    it 'sets the reference type as a Symbol' do
      dummy = Class.new(described_class)
      dummy.reference_type = 'foo'

      expect(dummy.reference_type).to eq(:foo)
    end
  end

  describe '#user_can_see_reference?' do
    let(:link) { Nokogiri::HTML.fragment('<a></a>').children[0] }

    context 'when the link has a data-project attribute' do
      it 'returns true if the attribute value equals the current project ID' do
        link['data-project'] = project.id.to_s

        expect(Ability.abilities).not_to receive(:allowed?)
        expect(parser.user_can_see_reference?(user, link)).to eq(true)
      end

      it 'returns true if the user can read the project' do
        other_project = create(:empty_project, :public)

        link['data-project'] = other_project.id.to_s

        expect(Ability.abilities).to receive(:allowed?).
          with(user, :read_project, other_project).
          and_return(true)

        expect(parser.user_can_see_reference?(user, link)).to eq(true)
      end

      it 'returns false when the attribute value is empty' do
        link['data-project'] = ''

        expect(parser.user_can_see_reference?(user, link)).to eq(false)
      end

      it 'returns false when the user can not read the project' do
        other_project = create(:empty_project, :public)

        link['data-project'] = other_project.id.to_s

        expect(Ability.abilities).to receive(:allowed?).
          with(user, :read_project, other_project).
          and_return(false)

        expect(parser.user_can_see_reference?(user, link)).to eq(false)
      end
    end

    context 'when the link does not have a data-project attribute' do
      it 'returns true' do
        expect(parser.user_can_see_reference?(user, link)).to eq(true)
      end
    end
  end

  describe '#user_can_reference?' do
    it 'returns true' do
      expect(parser.user_can_reference?(user, double(:link))).to eq(true)
    end
  end

  describe '#referenced_by' do
    it 'raises NotImplementedError' do
      link = double(:link)

      expect { parser.referenced_by(link) }.to raise_error(NotImplementedError)
    end
  end

  describe '#process' do
    it 'gathers the references for every node matching the reference type' do
      dummy = Class.new(described_class) do
        self.reference_type = :test
      end

      instance = dummy.new(project, user, user)
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
      expect(parser).to receive(:user_can_reference?).
        with(user, link).
        and_return(false)

      expect(parser).to receive(:referenced_by).with([])

      parser.gather_references([link])
    end

    it 'does not process links a user can not see' do
      expect(parser).to receive(:user_can_reference?).
        with(user, link).
        and_return(true)

      expect(parser).to receive(:user_can_see_reference?).
        with(user, link).
        and_return(false)

      expect(parser).to receive(:referenced_by).with([])

      parser.gather_references([link])
    end

    it 'returns the references if a user can reference and see a link' do
      expect(parser).to receive(:user_can_reference?).
        with(user, link).
        and_return(true)

      expect(parser).to receive(:user_can_see_reference?).
        with(user, link).
        and_return(true)

      expect(parser).to receive(:referenced_by).with([link])

      parser.gather_references([link])
    end
  end
end
