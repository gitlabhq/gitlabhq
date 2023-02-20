# frozen_string_literal: true

RSpec.shared_examples 'resource with exportable associations' do
  before do
    stub_licensed_features(stubbed_features) if stubbed_features.any?
  end

  describe '#exportable_association?' do
    let(:association) { single_association }

    subject { resource.exportable_association?(association, current_user: user) }

    it { is_expected.to be_falsey }

    context 'when user can read resource' do
      before do
        group.add_developer(user)
      end

      it { is_expected.to be_falsey }

      context "when user can read resource's association" do
        before do
          other_group.add_developer(user)
        end

        it { is_expected.to be_truthy }

        context 'for an unknown association' do
          let(:association) { :foo }

          it { is_expected.to be_falsey }
        end

        context 'for an unauthenticated user' do
          let(:user) { nil }

          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '#readable_records' do
    subject { resource.readable_records(association, current_user: user) }

    before do
      group.add_developer(user)
    end

    context 'when association not supported' do
      let(:association) { :foo }

      it { is_expected.to be_nil }
    end

    context 'when association is `:notes`' do
      let(:association) { :notes }

      it { is_expected.to match_array([readable_note]) }

      context 'when user have access' do
        before do
          other_group.add_developer(user)
        end

        it 'returns all records' do
          is_expected.to match_array([readable_note, restricted_note])
        end
      end
    end
  end
end
