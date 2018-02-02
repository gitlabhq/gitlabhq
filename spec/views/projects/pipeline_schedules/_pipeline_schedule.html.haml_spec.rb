require 'spec_helper'

describe 'projects/pipeline_schedules/_pipeline_schedule' do
  let(:owner) { create(:user) }
  let(:master) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly, project: project) }

  before do
    assign(:project, project)

    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:pipeline_schedule).and_return(pipeline_schedule)

    allow(view).to receive(:can?).and_return(true)
  end

  context 'taking ownership of schedule' do
    context 'when non-owner is signed in' do
      let(:user) { master }

      before do
        allow(view).to receive(:can?).with(master, :take_ownership_pipeline_schedule, pipeline_schedule).and_return(true)
      end

      it 'non-owner can take ownership of pipeline' do
        render

        expect(rendered).to have_link('Take ownership')
      end
    end

    context 'when owner is signed in' do
      let(:user) { owner }

      before do
        allow(view).to receive(:can?).with(owner, :take_ownership_pipeline_schedule, pipeline_schedule).and_return(false)
      end

      it 'owner cannot take ownership of pipeline' do
        render

        expect(rendered).not_to have_link('Take ownership')
      end
    end
  end
end
