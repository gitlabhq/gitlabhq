# frozen_string_literal: true

RSpec.shared_examples "migrating a deleted user's associated records to the ghost user" do |record_class, fields|
  record_class_name = record_class.to_s.titleize.downcase

  let(:project) do
    case record_class
    when MergeRequest
      create(:project, :repository)
    else
      create(:project)
    end
  end

  before do
    project.add_developer(user)
  end

  context "for a #{record_class_name} the user has created" do
    let!(:record) { created_record }
    let(:migrated_fields) { fields || [:author] }

    it "does not delete the #{record_class_name}" do
      service.execute

      expect(record_class.find_by_id(record.id)).to be_present
    end

    it "blocks the user before migrating #{record_class_name}s to the 'Ghost User'" do
      service.execute

      expect(user).to be_blocked
    end

    it 'migrates all associated fields to the "Ghost user"' do
      service.execute

      migrated_record = record_class.find_by_id(record.id)

      migrated_fields.each do |field|
        expect(migrated_record.public_send(field)).to eq(Users::Internal.ghost)
      end
    end

    it 'will only migrate specific records during a hard_delete' do
      service.execute(hard_delete: true)

      migrated_record = record_class.find_by_id(record.id)

      check_user = always_ghost ? Users::Internal.ghost : user

      migrated_fields.each do |field|
        expect(migrated_record.public_send(field)).to eq(check_user)
      end
    end

    describe "race conditions" do
      context "when #{record_class_name} migration fails and is rolled back" do
        before do
          allow_next_instance_of(ActiveRecord::Associations::CollectionProxy)
            .to receive(:update_all).and_raise(ActiveRecord::StatementTimeout)
        end

        it 'rolls back the user block' do
          expect { service.execute }.to raise_error(ActiveRecord::StatementTimeout)

          expect(user.reload).not_to be_blocked
        end

        it "doesn't unblock a previously-blocked user" do
          expect(user.starred_projects).to receive(:update_all).and_call_original
          user.block

          expect { service.execute }.to raise_error(ActiveRecord::StatementTimeout)

          expect(user.reload).to be_blocked
        end
      end

      it "blocks the user before #{record_class_name} migration begins" do
        expect(service).to receive("migrate_#{record_class_name.parameterize(separator: '_').pluralize}".to_sym) do
          expect(user.reload).to be_blocked
        end

        service.execute
      end
    end
  end
end
