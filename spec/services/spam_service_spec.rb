require 'spec_helper'

describe SpamService, services: true do
  describe '#when_recaptcha_verified' do
    def check_spam(issue, request, recaptcha_verified)
      described_class.new(issue, request).when_recaptcha_verified(recaptcha_verified) do
        'yielded'
      end
    end

    it 'yields block when recaptcha was already verified' do
      issue = build_stubbed(:issue)

      expect(check_spam(issue, nil, true)).to eql('yielded')
    end

    context 'when recaptcha was not verified' do
      let(:project) { create(:project, :public) }
      let(:issue)   { create(:issue, project: project) }
      let(:request) { double(:request, env: {}) }

      context 'when indicated as spam by akismet' do
        before { allow(AkismetService).to receive(:new).and_return(double(is_spam?: true)) }

        it 'doesnt check as spam when request is missing' do
          check_spam(issue, nil, false)

          expect(issue.spam).to be_falsey
        end

        it 'checks as spam' do
          check_spam(issue, request, false)

          expect(issue.spam).to be_truthy
        end

        it 'creates a spam log' do
          expect { check_spam(issue, request, false) }
            .to change { SpamLog.count }.from(0).to(1)
        end

        it 'doesnt yield block' do
          expect(check_spam(issue, request, false))
            .to eql(SpamLog.last)
        end
      end

      context 'when not indicated as spam by akismet' do
        before { allow(AkismetService).to receive(:new).and_return(double(is_spam?: false)) }

        it 'returns false' do
          expect(check_spam(issue, request, false)).to be_falsey
        end

        it 'does not create a spam log' do
          expect { check_spam(issue, request, false) }
            .not_to change { SpamLog.count }
        end
      end
    end
  end
end
