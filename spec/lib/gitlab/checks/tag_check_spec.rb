# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::TagCheck, feature_category: :source_code_management do
  include_context 'change access checks context'

  describe '#validate!' do
    let(:ref) { 'refs/tags/v1.0.0' }

    it 'raises an error when user does not have access' do
      allow(user_access).to receive(:can_do_action?).with(:admin_tag).and_return(false)

      expect { change_check.validate! }.to raise_error(
        Gitlab::GitAccess::ForbiddenError,
        'You are not allowed to change existing tags on this project.'
      )
    end

    describe "prohibited tags check" do
      it 'prohibits tags name that include refs/heads at the head' do
        allow(change_check).to receive(:tag_name).and_return("refs/heads/foo")

        expect { change_check.validate! }.to raise_error(
          Gitlab::GitAccess::ForbiddenError,
          "You cannot create a tag with a prohibited pattern."
        )
      end

      it "prohibits tag names that include refs/tags/ at the head" do
        allow(change_check).to receive(:tag_name).and_return("refs/tags/foo")

        expect { change_check.validate! }.to raise_error(
          Gitlab::GitAccess::ForbiddenError,
          "You cannot create a tag with a prohibited pattern."
        )
      end

      it "doesn't prohibit a nested refs/tags/ string in a tag name" do
        allow(change_check).to receive(:tag_name).and_return("fix-for-refs/tags/foo")

        expect { change_check.validate! }.not_to raise_error
      end

      it "prohibits tag names that include characters incompatible with UTF-8" do
        allow(change_check).to receive(:tag_name).and_return("v6.0.0-\xCE.BETA")

        expect { change_check.validate! }.to raise_error(
          Gitlab::GitAccess::ForbiddenError,
          "Tag names must be valid when converted to UTF-8 encoding"
        )
      end

      it "doesn't prohibit UTF-8 compatible characters" do
        allow(change_check).to receive(:tag_name).and_return("v6.0.0-Ü.BETA")

        expect { change_check.validate! }.not_to raise_error
      end

      context "when prohibited_tag_name_encoding_check feature flag is disabled" do
        before do
          stub_feature_flags(prohibited_tag_name_encoding_check: false)
          allow(change_check).to receive(:validate_tag_name_not_sha_like!)
        end

        it "doesn't prohibit tag names that include characters incompatible with UTF-8" do
          allow(change_check).to receive(:tag_name).and_return("v6.0.0-\xCE.BETA")

          expect { change_check.validate! }.not_to raise_error
        end

        it "doesn't prohibit UTF-8 compatible characters" do
          allow(change_check).to receive(:tag_name).and_return("v6.0.0-Ü.BETA")

          expect { change_check.validate! }.not_to raise_error
        end
      end

      describe "deleting a refs/tags headed tag" do
        let(:newrev) { "0000000000000000000000000000000000000000" }
        let(:ref) { "refs/tags/refs/tags/267208abfe40e546f5e847444276f7d43a39503e" }

        it "doesn't prohibit the deletion of a refs/tags/ tag name" do
          expect { change_check.validate! }.not_to raise_error
        end
      end

      it "forbids SHA-1 values" do
        allow(change_check)
          .to receive(:tag_name)
          .and_return("267208abfe40e546f5e847444276f7d43a39503e")

        expect { change_check.validate! }.to raise_error(
          Gitlab::GitAccess::ForbiddenError,
          "You cannot create a tag with a SHA-1 or SHA-256 tag name."
        )
      end

      it "forbids SHA-256 values" do
        allow(change_check)
          .to receive(:tag_name)
          .and_return("09b9fd3ea68e9b95a51b693a29568c898e27d1476bbd83c825664f18467fc175")

        expect { change_check.validate! }.to raise_error(
          Gitlab::GitAccess::ForbiddenError,
          "You cannot create a tag with a SHA-1 or SHA-256 tag name."
        )
      end

      it "forbids '{SHA-1}{+anything}' values" do
        allow(change_check)
          .to receive(:tag_name)
          .and_return("267208abfe40e546f5e847444276f7d43a39503e-")

        expect { change_check.validate! }.to raise_error(
          Gitlab::GitAccess::ForbiddenError,
          "You cannot create a tag with a SHA-1 or SHA-256 tag name."
        )
      end

      it "forbids '{SHA-256}{+anything} values" do
        allow(change_check)
          .to receive(:tag_name)
          .and_return("09b9fd3ea68e9b95a51b693a29568c898e27d1476bbd83c825664f18467fc175-")

        expect { change_check.validate! }.to raise_error(
          Gitlab::GitAccess::ForbiddenError,
          "You cannot create a tag with a SHA-1 or SHA-256 tag name."
        )
      end

      it "allows SHA-1 values to be appended to the tag name" do
        allow(change_check)
          .to receive(:tag_name)
          .and_return("fix-267208abfe40e546f5e847444276f7d43a39503e")

        expect { change_check.validate! }.not_to raise_error
      end

      it "allows SHA-256 values to be appended to the tag name" do
        allow(change_check)
          .to receive(:tag_name)
          .and_return("fix-09b9fd3ea68e9b95a51b693a29568c898e27d1476bbd83c825664f18467fc175")

        expect { change_check.validate! }.not_to raise_error
      end
    end

    context 'with protected tag' do
      let!(:protected_tag) { create(:protected_tag, project: project, name: 'v*') }

      context 'as maintainer' do
        before do
          project.add_maintainer(user)
        end

        describe 'deleting a tag' do
          let(:oldrev) { 'be93687618e4b132087f430a4d8fc3a609c9b77c' }
          let(:newrev) { '0000000000000000000000000000000000000000' }

          context 'when deleting via web interface' do
            let(:protocol) { 'web' }

            it 'is allowed' do
              expect { change_check.validate! }.not_to raise_error
            end
          end

          context 'when deleting via SSH' do
            it 'is prevented' do
              expect { change_check.validate! }.to raise_error(
                Gitlab::GitAccess::ForbiddenError,
                'You can only delete protected tags using the web interface.'
              )
            end
          end
        end

        describe 'updating a tag' do
          let(:oldrev) { 'be93687618e4b132087f430a4d8fc3a609c9b77c' }
          let(:newrev) { '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51' }

          it 'is prevented' do
            expect { change_check.validate! }.to raise_error(
              Gitlab::GitAccess::ForbiddenError, 'Protected tags cannot be updated.'
            )
          end
        end
      end

      context 'as developer' do
        before do
          project.add_developer(user)
        end

        describe 'deleting a tag' do
          let(:oldrev) { 'be93687618e4b132087f430a4d8fc3a609c9b77c' }
          let(:newrev) { '0000000000000000000000000000000000000000' }

          it 'is prevented' do
            expect { change_check.validate! }.to raise_error(
              Gitlab::GitAccess::ForbiddenError,
              'You are not allowed to delete protected tags from this project. ' \
              'Only a project maintainer or owner can delete a protected tag.'
            )
          end
        end
      end

      describe 'creating a tag' do
        let(:oldrev) { '0000000000000000000000000000000000000000' }
        let(:newrev) { '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51' }
        let(:ref) { 'refs/tags/v9.1.0' }

        it 'prevents creation below access level' do
          expect { change_check.validate! }.to raise_error(
            Gitlab::GitAccess::ForbiddenError,
            'You are not allowed to create this tag as it is protected.'
          )
        end

        context 'when user has access' do
          let!(:protected_tag) { create(:protected_tag, :developers_can_create, project: project, name: 'v*') }

          it 'allows tag creation' do
            expect { change_check.validate! }.not_to raise_error
          end

          context 'when tag name is the same as default branch' do
            let(:ref) { "refs/tags/#{project.default_branch}" }

            it 'is prevented' do
              expect { change_check.validate! }.to raise_error(
                Gitlab::GitAccess::ForbiddenError,
                'You cannot use default branch name to create a tag'
              )
            end
          end
        end
      end
    end
  end
end
