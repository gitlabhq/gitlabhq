require "spec_helper"

shared_examples "migrating a deleted user's associated records to the ghost user" do |record_class|
  record_class_name = record_class.to_s.titleize.downcase

  let(:project) { create(:project) }

  before do
    project.add_developer(user)
  end

  context "for a #{record_class_name} the user has created" do
    let!(:record) { created_record }

    it "does not delete the #{record_class_name}" do
      service.execute

      expect(record_class.find_by_id(record.id)).to be_present
    end

    it "migrates the #{record_class_name} so that the 'Ghost User' is the #{record_class_name} owner" do
      service.execute

      migrated_record = record_class.find_by_id(record.id)

      if migrated_record.respond_to?(:author)
        expect(migrated_record.author).to eq(User.ghost)
      else
        expect(migrated_record.send(author_alias)).to eq(User.ghost)
      end
    end

    it "blocks the user before migrating #{record_class_name}s to the 'Ghost User'" do
      service.execute

      expect(user).to be_blocked
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
