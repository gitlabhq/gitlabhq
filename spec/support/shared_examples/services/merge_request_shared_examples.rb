# frozen_string_literal: true

RSpec.shared_examples 'reviewer_ids filter' do
  context 'filter_reviewer' do
    let(:opts) { super().merge(reviewer_ids_param) }

    context 'without reviewer_ids' do
      let(:reviewer_ids_param) { {} }

      it 'contains no reviewer_ids' do
        expect(execute.reviewers).to eq []
      end
    end

    context 'with reviewer_ids' do
      let(:reviewer_ids_param) { { reviewer_ids: [reviewer1.id, reviewer2.id] } }

      let(:reviewer1) { create(:user) }
      let(:reviewer2) { create(:user) }

      context 'when the current user can admin the merge_request' do
        context 'when merge_request_reviewer feature is enabled' do
          before do
            stub_feature_flags(merge_request_reviewer: true)
          end

          context 'with a reviewer who can read the merge_request' do
            before do
              project.add_developer(reviewer1)
            end

            it 'contains reviewers who can read the merge_request' do
              expect(execute.reviewers).to contain_exactly(reviewer1)
            end
          end
        end

        context 'when merge_request_reviewer feature is disabled' do
          before do
            stub_feature_flags(merge_request_reviewer: false)
          end

          it 'contains no reviewers' do
            expect(execute.reviewers).to eq []
          end
        end
      end

      context 'when the current_user cannot admin the merge_request' do
        before do
          project.add_developer(user)
        end

        it 'contains no reviewers' do
          expect(execute.reviewers).to eq []
        end
      end
    end
  end
end
