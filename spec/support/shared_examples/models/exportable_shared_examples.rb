# frozen_string_literal: true

RSpec.shared_examples 'an exportable' do |restricted_association: :project|
  let_it_be(:user) { create(:user) }

  describe '#exportable_association?' do
    let(:association) { restricted_association }

    subject { resource.exportable_association?(association, current_user: user) }

    it { is_expected.to be_falsey }

    context 'when user can only read resource' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
          .with(user, :"read_#{resource.to_ability_name}", resource)
          .and_return(true)
      end

      it { is_expected.to be_falsey }

      context "when user can read resource's association" do
        before do
          allow(resource).to receive(:readable_record?).with(anything, user).and_return(true)
        end

        it { is_expected.to be_truthy }

        context 'for an unknown association' do
          let(:association) { :foo }

          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '#to_authorized_json' do
    let(:options) { { include: [{ notes: { only: [:id] } }] } }

    subject { resource.to_authorized_json(keys, user, options) }

    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
        .with(user, :"read_#{resource.to_ability_name}", resource)
        .and_return(true)
    end

    context 'when association not supported' do
      let(:keys) { [:foo] }

      it { is_expected.not_to include('foo') }
    end

    context 'when association is `:notes`' do
      let_it_be(:readable_note) { create(:system_note, noteable: resource, project: project, note: 'readable') }
      let_it_be(:restricted_note) { create(:system_note, noteable: resource, project: project, note: 'restricted') }

      let(:restricted_note_access) { false }
      let(:keys) { [:notes] }

      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :read_note, readable_note).and_return(true)
        allow(Ability).to receive(:allowed?).with(user, :read_note, restricted_note).and_return(restricted_note_access)
      end

      it { is_expected.to include("\"notes\":[{\"id\":#{readable_note.id}}]") }

      context 'when user have access to all notes' do
        let(:restricted_note_access) { true }

        it 'string includes all notes' do
          is_expected.to include("\"notes\":[{\"id\":#{readable_note.id}},{\"id\":#{restricted_note.id}}]")
        end
      end
    end
  end
end
