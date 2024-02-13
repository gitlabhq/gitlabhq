# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Callbacks::Description, feature_category: :portfolio_management do
  let_it_be(:random_user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  let(:params) { { description: 'updated description' } }
  let(:current_user) { author }
  let(:work_item) do
    create(
      :work_item,
      author: author,
      project: project,
      description: 'old description',
      last_edited_at: Date.yesterday,
      last_edited_by: random_user
    )
  end

  describe '#after_initialize' do
    let(:service) { described_class.new(issuable: work_item, current_user: current_user, params: params) }

    subject(:after_initialize_callback) { service.after_initialize }

    shared_examples 'sets work item description' do
      it 'correctly sets work item description value' do
        subject

        expect(work_item.description).to eq(params[:description])
        expect(work_item.last_edited_by).to eq(current_user)
        expect(work_item.last_edited_at).to be_within(2.seconds).of(Time.current)
      end
    end

    shared_examples 'does not set work item description' do
      it 'does not change work item description value' do
        subject

        expect(work_item.description).to eq('old description')
        expect(work_item.last_edited_by).to eq(random_user)
        expect(work_item.last_edited_at).to eq(Date.yesterday)
      end
    end

    context 'when user has permission to update description' do
      context 'when user is work item author' do
        let(:current_user) { author }

        it_behaves_like 'sets work item description'
      end

      context 'when user is a project reporter' do
        let(:current_user) { reporter }

        before_all do
          project.add_reporter(reporter)
        end

        it_behaves_like 'sets work item description'
      end

      context 'when description is nil' do
        let(:current_user) { author }
        let(:params) { { description: nil } }

        it_behaves_like 'sets work item description'
      end

      context 'when description is empty' do
        let(:current_user) { author }
        let(:params) { { description: '' } }

        it_behaves_like 'sets work item description'
      end

      context 'when description param is not present' do
        let(:params) { {} }

        it_behaves_like 'does not set work item description'
      end

      context 'when widget does not exist in new type' do
        let(:current_user) { author }
        let(:params) { {} }

        before do
          allow(service).to receive(:excluded_in_new_type?).and_return(true)
          work_item.update!(description: 'test')
        end

        it "resets the work item's description" do
          expect { after_initialize_callback }
            .to change { work_item.description }
            .from('test')
            .to(nil)
        end
      end
    end

    context 'when user does not have permission to update description' do
      context 'when user is a project guest' do
        let(:current_user) { guest }

        before_all do
          project.add_guest(guest)
        end

        it_behaves_like 'does not set work item description'
      end

      context 'with private project' do
        let_it_be(:project) { create(:project) }

        context 'when user is work item author' do
          let(:current_user) { author }

          it_behaves_like 'does not set work item description'
        end
      end
    end
  end
end
