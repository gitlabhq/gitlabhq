# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DesignManagement::Action do
  describe 'relations' do
    it { is_expected.to belong_to(:design) }
    it { is_expected.to belong_to(:version) }
  end

  describe 'scopes' do
    let_it_be(:issue) { create(:issue) }
    let_it_be(:design_a) { create(:design, issue: issue) }
    let_it_be(:design_b) { create(:design, issue: issue) }

    context 'with 3 designs' do
      let_it_be(:design_c) { create(:design, issue: issue) }

      let_it_be(:action_a_1) { create(:design_action, design: design_a) }
      let_it_be(:action_a_2) { create(:design_action, design: design_a, event: :deletion) }
      let_it_be(:action_b)   { create(:design_action, design: design_b) }
      let_it_be(:action_c)   { create(:design_action, design: design_c, event: :deletion) }

      describe '.most_recent' do
        let(:designs) { [design_a, design_b, design_c] }

        before_all do
          create(:design_version, designs: [design_a, design_b, design_c])
          create(:design_version, designs: [design_a, design_b])
          create(:design_version, designs: [design_a])
        end

        it 'finds the correct version for each design' do
          dvs = described_class.where(design: designs)

          expected = designs
            .map(&:id)
            .zip(dvs.order("version_id DESC").pluck(:version_id).uniq)

          actual = dvs.most_recent.map { |dv| [dv.design_id, dv.version_id] }

          expect(actual).to eq(expected)
        end
      end

      describe '.by_design' do
        it 'returns the actions by design_id' do
          expect(described_class.by_design([design_a.id, design_b.id]))
            .to match_array([action_a_1, action_a_2, action_b])
        end
      end

      describe '.with_version' do
        it 'preloads the version' do
          actions = described_class.with_version

          expect { actions.map(&:version) }.not_to exceed_query_limit(2)
          expect(actions.count).to be > 2
        end
      end

      describe '.by_event' do
        it 'returns the actions by event type' do
          expect(described_class.by_event(:deletion)).to match_array([action_a_2, action_c])
        end
      end
    end

    describe '.up_to_version' do
      # let bindings are not available in before(:all) contexts,
      # so we need to redefine the array on each construction.
      let_it_be(:oldest) { create(:design_version, designs: [design_a, design_b]) }
      let_it_be(:middle) { create(:design_version, designs: [design_a, design_b]) }
      let_it_be(:newest) { create(:design_version, designs: [design_a, design_b]) }

      subject { described_class.where(design: issue.designs).up_to_version(version) }

      context 'the version is nil' do
        let(:version) { nil }

        it 'returns all design_versions' do
          is_expected.to have_attributes(size: 6)
        end
      end

      context 'when given a Version instance' do
        context 'the version is the most current' do
          let(:version) { newest }

          it { is_expected.to have_attributes(size: 6) }
        end

        context 'the version is the oldest' do
          let(:version) { oldest }

          it { is_expected.to have_attributes(size: 2) }
        end

        context 'the version is the middle one' do
          let(:version) { middle }

          it { is_expected.to have_attributes(size: 4) }
        end
      end

      context 'when given a commit SHA' do
        context 'the version is the most current' do
          let(:version) { newest.sha }

          it { is_expected.to have_attributes(size: 6) }
        end

        context 'the version is the oldest' do
          let(:version) { oldest.sha }

          it { is_expected.to have_attributes(size: 2) }
        end

        context 'the version is the middle one' do
          let(:version) { middle.sha }

          it { is_expected.to have_attributes(size: 4) }
        end
      end

      context 'when given a String that is not a commit SHA' do
        let(:version) { 'foo' }

        it { expect { subject }.to raise_error(ArgumentError) }
      end
    end
  end

  describe '#uploads_sharding_key' do
    it 'returns namespace_id' do
      namespace = build_stubbed(:namespace)
      design = build_stubbed(:design, namespace_id: namespace.id)
      design_action = build_stubbed(:design_action, design: design)

      expect(design_action.uploads_sharding_key).to eq(namespace_id: namespace.id)
    end
  end
end
