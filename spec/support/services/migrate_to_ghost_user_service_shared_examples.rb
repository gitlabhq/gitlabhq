require "spec_helper"

shared_examples "migrating a deleted user's associated records to the ghost user" do |record_class, fields|
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

    it 'migrates all associated fields to te "Ghost user"' do
      service.execute

      migrated_record = record_class.find_by_id(record.id)

      migrated_fields.each do |field|
        expect(migrated_record.public_send(field)).to eq(User.ghost)
      end
    end

    context "race conditions" do
      context "when #{record_class_name} migration fails and is rolled back" do
        before do
          expect_any_instance_of(record_class::ActiveRecord_Associations_CollectionProxy)
            .to receive(:update_all).and_raise(ActiveRecord::Rollback)
        end

        it 'rolls back the user block' do
          service.execute

          expect(user.reload).not_to be_blocked
        end

        it "doesn't unblock an previously-blocked user" do
          user.block

          service.execute

          expect(user.reload).to be_blocked
        end
      end

      context "when #{record_class_name} migration fails with a non-rollback exception" do
        before do
          expect_any_instance_of(record_class::ActiveRecord_Associations_CollectionProxy)
            .to receive(:update_all).and_raise(ArgumentError)
        end

        it 'rolls back the user block' do
          service.execute rescue nil

          expect(user.reload).not_to be_blocked
        end

        it "doesn't unblock an previously-blocked user" do
          user.block

          service.execute rescue nil

          expect(user.reload).to be_blocked
        end
      end

      it "blocks the user before #{record_class_name} migration begins" do
        expect(service).to receive("migrate_#{record_class_name.parameterize('_')}s".to_sym) do
          expect(user.reload).to be_blocked
        end

        service.execute
      end
    end
  end
end
