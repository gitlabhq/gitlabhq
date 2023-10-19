# frozen_string_literal: true

# This shared example requires the following variables
# issuable_link
# issuable
# issuable_class
# issuable_link_factory
RSpec.shared_examples 'issuable link' do
  describe 'Associations' do
    it { is_expected.to belong_to(:source).class_name(issuable_class) }
    it { is_expected.to belong_to(:target).class_name(issuable_class) }
  end

  describe 'Validation' do
    subject { issuable_link }

    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:target) }

    it do
      is_expected.to validate_uniqueness_of(:source)
                       .scoped_to(:target_id)
                       .with_message(/already related/)
    end

    it 'is not valid if an opposite link already exists' do
      issuable_link = create_issuable_link(subject.target, subject.source)

      expect(issuable_link).to be_invalid
      expect(issuable_link.errors[:source])
        .to include("is already related to this #{issuable.issuable_type.humanize(capitalize: false)}")
    end

    context 'when it relates to itself' do
      context 'when target is nil' do
        it 'does not invalidate object with self relation error' do
          issuable_link = create_issuable_link(issuable, nil)

          issuable_link.valid?

          expect(issuable_link.errors[:source]).to be_empty
        end
      end

      context 'when source and target are present' do
        it 'invalidates object' do
          issuable_link = create_issuable_link(issuable, issuable)

          expect(issuable_link).to be_invalid
          expect(issuable_link.errors[:source]).to include('cannot be related to itself')
        end
      end
    end

    context 'when max number of links is exceeded' do
      subject(:link) { create_issuable_link(issuable, issuable2) }

      shared_examples 'invalid due to exceeding max number of links' do
        let(:stubbed_limit) { 1 }
        let(:issuable_name) { described_class.issuable_name }
        let(:error_msg) do
          "This #{issuable_name} would exceed the maximum number of " \
            "linked #{issuable_name.pluralize} (#{stubbed_limit})."
        end

        before do
          create(issuable_link_factory, source: source, target: target)
          stub_const("IssuableLink::MAX_LINKS_COUNT", stubbed_limit)
        end

        specify do
          is_expected.to be_invalid
          expect(link.errors.messages[error_item]).to include(error_msg)
        end
      end

      context 'when source exceeds max' do
        let(:source) { issuable }
        let(:target) { issuable3 }
        let(:error_item) { :source }

        it_behaves_like 'invalid due to exceeding max number of links'
      end

      context 'when target exceeds max' do
        let(:source) { issuable2 }
        let(:target) { issuable3 }
        let(:error_item) { :target }

        it_behaves_like 'invalid due to exceeding max number of links'
      end
    end

    def create_issuable_link(source, target)
      build(issuable_link_factory, source: source, target: target)
    end
  end

  describe 'scopes' do
    describe '.for_source_or_target' do
      it 'returns only links where id is either source or target id' do
        link1 = create(issuable_link_factory, source: issuable_link.source)
        link2 = create(issuable_link_factory, target: issuable_link.source)
        # unrelated link, should not be included in result list
        create(issuable_link_factory) # rubocop: disable Rails/SaveBang

        expect(described_class.for_source_or_target(issuable_link.source_id)).to match_array([issuable_link, link1, link2])
      end
    end
  end

  describe '.link_type' do
    it { is_expected.to define_enum_for(:link_type).with_values(relates_to: 0, blocks: 1) }

    it 'provides the "related" as default link_type' do
      expect(issuable_link.link_type).to eq 'relates_to'
    end
  end
end
