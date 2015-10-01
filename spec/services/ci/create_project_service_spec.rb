require 'spec_helper'

describe Ci::CreateProjectService do
  let(:service) { Ci::CreateProjectService.new }
  let(:current_user) { double.as_null_object }
  let(:project) { FactoryGirl.create :project }

  describe :execute do
    context 'valid params' do
      subject { service.execute(current_user, project) }

      it { is_expected.to be_kind_of(Ci::Project) }
      it { is_expected.to be_persisted }
    end

    context 'without project dump' do
      it 'should raise exception' do
        expect { service.execute(current_user, '', '') }.
          to raise_error(NoMethodError)
      end
    end

    context "forking" do
      let(:ci_origin_project) do
        FactoryGirl.create(:ci_project, shared_runners_enabled: true, public: true, allow_git_fetch: true)
      end

      subject { service.execute(current_user, project, ci_origin_project) }

      it "uses project as a template for settings and jobs" do
        expect(subject.shared_runners_enabled).to be_truthy
        expect(subject.public).to be_truthy
        expect(subject.allow_git_fetch).to be_truthy
      end
    end
  end
end
