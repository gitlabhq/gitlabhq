require 'spec_helper'

describe EE::ProtectedRefAccess do
  included_in_classes = [ProtectedBranch::MergeAccessLevel,
                         ProtectedBranch::PushAccessLevel,
                         ProtectedTag::CreateAccessLevel]

  included_in_classes.each do |included_in_class|
    context "in #{included_in_class}" do
      let(:access_level) do
        factory_name = included_in_class.name.underscore.tr('/', '_')
        build(factory_name)
      end

      it "#{included_in_class} includes {described_class}" do
        expect(included_in_class.included_modules).to include(described_class)
      end

      context 'with the `protected_refs_for_users` feature disabled' do
        before do
          stub_licensed_features(protected_refs_for_users: false)
        end

        it "allows creating an #{included_in_class} with a group" do
          access_level.group = create(:group)

          expect(access_level).not_to be_valid
          expect(access_level.errors).to include(:group)
        end

        it "allows creating an #{included_in_class} with a user" do
          access_level.user = create(:user)

          expect(access_level).not_to be_valid
          expect(access_level.errors).to include(:user)
        end
      end

      context 'with the `protected_refs_for_users` feature enabled' do
        before do
          stub_licensed_features(protected_refs_for_users: true)
        end

        it "allows creating an #{included_in_class} with a group" do
          access_level.group = create(:group)

          expect(access_level).to be_valid
        end

        it "allows creating an #{included_in_class} with a user" do
          access_level.user = create(:user)

          expect(access_level).to be_valid
        end
      end
    end
  end
end
