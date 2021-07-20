# frozen_string_literal: true

# required context:
# - importable: group or project
# - relation_hash: a note relation that's being imported
# - created_object: the object created with the relation factory
RSpec.shared_examples 'Notes user references' do
  let(:relation_sym) { :notes }
  let(:mapped_user) { create(:user) }
  let(:exported_member) do
    {
      'id' => 111,
      'access_level' => 30,
      'source_id' => 1,
      'source_type' => importable.instance_of?(Project) ? 'Project' : 'Namespace',
      'user_id' => 3,
      'notification_level' => 3,
      'created_at' => '2016-11-18T09:29:42.634Z',
      'updated_at' => '2016-11-18T09:29:42.634Z',
      'user' => {
        'id' => 999,
        'email' => mapped_user.email,
        'username' => mapped_user.username
      }
    }
  end

  let(:members_mapper) do
    Gitlab::ImportExport::MembersMapper.new(
      exported_members: [exported_member].compact,
      user: importer_user,
      importable: importable
    )
  end

  shared_examples 'sets the note author to the importer user' do
    it { expect(created_object.author).to eq(importer_user) }
  end

  shared_examples 'sets the note author to the mapped user' do
    it { expect(created_object.author).to eq(mapped_user) }
  end

  shared_examples 'does not add original autor note' do
    it { expect(created_object.note).not_to include('*By Administrator') }
  end

  shared_examples 'adds original autor note' do
    it { expect(created_object.note).to include('*By Administrator') }
  end

  context 'when the importer is admin' do
    let(:importer_user) { create(:admin) }

    context 'and the note author is not mapped' do
      let(:exported_member) { nil }

      include_examples 'sets the note author to the importer user'

      include_examples 'adds original autor note'
    end

    context 'and the note author is the importer user' do
      let(:mapped_user) { importer_user }

      include_examples 'sets the note author to the mapped user'

      include_examples 'does not add original autor note'
    end

    context 'and the note author exists in the target instance' do
      let(:mapped_user) { create(:user) }

      include_examples 'sets the note author to the mapped user'

      include_examples 'does not add original autor note'
    end
  end

  context 'when the importer is not admin' do
    let(:importer_user) { create(:user) }

    context 'and the note author is not mapped' do
      let(:exported_member) { nil }

      include_examples 'sets the note author to the importer user'

      include_examples 'adds original autor note'
    end

    context 'and the note author is the importer user' do
      let(:mapped_user) { importer_user }

      include_examples 'sets the note author to the importer user'

      include_examples 'adds original autor note'
    end

    context 'and the note author exists in the target instance' do
      let(:mapped_user) { create(:user) }

      include_examples 'sets the note author to the importer user'

      include_examples 'adds original autor note'
    end
  end
end
