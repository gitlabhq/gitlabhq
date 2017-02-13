require 'spec_helper'

describe SpamService, services: true do
  describe '#check' do
    let(:project) { create(:project, :public) }
    let(:issue)   { create(:issue, project: project) }
    let(:request) { double(:request, env: {}) }

    def check_spam(issue, request)
      described_class.new(issue, request).check
    end

    context 'when indicated as spam by akismet' do
      before { allow(AkismetService).to receive(:new).and_return(double(is_spam?: true)) }

      it 'returns false when request is missing' do
        expect(check_spam(issue, nil)).to be_falsey
      end

      it 'returns false when issue is not public' do
        issue = create(:issue, project: create(:project, :private))

        expect(check_spam(issue, request)).to be_falsey
      end

      it 'returns true' do
        expect(check_spam(issue, request)).to be_truthy
      end

      it 'creates a spam log' do
        expect { check_spam(issue, request) }.to change { SpamLog.count }.from(0).to(1)
      end
    end

    context 'when not indicated as spam by akismet' do
      before { allow(AkismetService).to receive(:new).and_return(double(is_spam?: false)) }

      it 'returns false' do
        expect(check_spam(issue, request)).to be_falsey
      end

      it 'does not create a spam log' do
        expect { check_spam(issue, request) }.not_to change { SpamLog.count }
      end
    end
  end
end
