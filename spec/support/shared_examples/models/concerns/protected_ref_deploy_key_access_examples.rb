# frozen_string_literal: true

RSpec.shared_examples 'protected ref deploy_key access' do
  let_it_be(:described_instance) { described_class.model_name.singular }
  let_it_be(:protected_ref_name) { described_class.module_parent.model_name.singular }
  let_it_be(:project) { create(:project) }
  let_it_be(:protected_ref) { create(protected_ref_name, project: project) } # rubocop:disable Rails/SaveBang

  describe 'associations' do
    it { is_expected.to belong_to(:deploy_key) }
  end

  describe 'validations' do
    context 'when deploy_key?' do
      context 'when deploy key enabled for the project' do
        let(:deploy_key) do
          create(:deploy_keys_project, :write_access, project: project).deploy_key
        end

        it 'is valid' do
          level = build(described_instance, protected_ref_name => protected_ref, deploy_key: deploy_key)

          expect(level).to be_valid
        end
      end

      context 'when a deploy key already added for this access level' do
        let(:deploy_key) { create(:deploy_keys_project, :write_access, project: project).deploy_key }

        before do
          create(described_instance, protected_ref_name => protected_ref, deploy_key: deploy_key)
        end

        subject(:access_level) do
          build(described_instance, protected_ref_name => protected_ref, deploy_key: deploy_key)
        end

        it 'is not valid', :aggregate_failures do
          is_expected.to be_invalid
          expect(access_level.errors.full_messages).to contain_exactly('Deploy key has already been taken')
        end
      end

      context 'when deploy key is not enabled for the project' do
        subject(:access_level) do
          build(described_instance, protected_ref_name => protected_ref, deploy_key: create(:deploy_key))
        end

        it 'is not valid', :aggregate_failures do
          is_expected.to be_invalid
          expect(access_level.errors.full_messages).to contain_exactly('Deploy key is not enabled for this project')
        end
      end

      context 'when deploy key is not active for the project' do
        subject(:access_level) do
          deploy_key = create(:deploy_keys_project, :readonly_access, project: project).deploy_key
          build(described_instance, protected_ref_name => protected_ref, deploy_key: deploy_key)
        end

        it 'is not valid', :aggregate_failures do
          is_expected.to be_invalid
          expect(access_level.errors.full_messages).to contain_exactly('Deploy key is not enabled for this project')
        end
      end
    end
  end

  describe '#check_access' do
    let_it_be(:user) { create(:user) }
    let_it_be(:deploy_key) { create(:deploy_key, user: user) }
    let_it_be(:deploy_keys_project) do
      create(:deploy_keys_project, :write_access, project: project, deploy_key: deploy_key)
    end

    before_all do
      project.add_maintainer(user)
    end

    context "when this #{described_class.model_name.singular} is tied to a deploy key" do
      let!(:access_level) do
        create(described_instance, protected_ref_name => protected_ref, deploy_key: deploy_key)
      end

      context 'when the deploy key is among the active keys for this project' do
        it { expect(access_level.check_access(user)).to be_truthy }
      end

      context 'when user is missing' do
        it { expect(access_level.check_access(nil)).to be_falsey }
      end

      context 'when deploy key does not belong to the user' do
        let(:another_user) { create(:user) }

        it { expect(access_level.check_access(another_user)).to be_falsey }
      end

      context 'when user cannot access the project' do
        before do
          allow(user).to receive(:can?).with(:read_project, project).and_return(false)
        end

        it { expect(access_level.check_access(user)).to be_falsey }
      end

      context 'when the deploy key is not among the active keys of this project' do
        before do
          deploy_keys_project.update!(can_push: false)
        end

        after do
          deploy_keys_project.update!(can_push: true)
        end

        it { expect(access_level.check_access(user)).to be_falsey }
      end
    end
  end

  describe '#type' do
    let(:access_level) { build(described_instance) }

    context 'when deploy_key?' do
      let(:access_level) { build(described_instance, deploy_key: build(:deploy_key)) }

      it 'returns :deploy_key' do
        expect(access_level.type).to eq(:deploy_key)
      end
    end
  end
end
