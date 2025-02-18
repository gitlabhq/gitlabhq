# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::EmailsOnPush do
  let_it_be(:project) { create(:project, :repository) }
  let(:recipients) { 'foo@bar.com duplicate@example.com Duplicate@example.com invalid-email' }

  subject(:integration) { described_class.create!(project: project, recipients: recipients, active: true) }

  describe 'Validations' do
    context 'when integration is active' do
      before do
        integration.active = true
      end

      it { is_expected.to validate_presence_of(:recipients) }
    end

    context 'when integration is inactive' do
      before do
        integration.active = false
      end

      it { is_expected.not_to validate_presence_of(:recipients) }
    end

    describe 'validates number of recipients' do
      before do
        stub_const("Integrations::Base::EmailsOnPush::RECIPIENTS_LIMIT", 2)
      end

      subject(:integration) { described_class.new(project: project, recipients: recipients, active: true) }

      context 'with valid number of recipients' do
        let(:recipients) { 'foo@bar.com duplicate@example.com Duplicate@example.com invalid-email' }

        it 'does not count duplicates and invalid emails' do
          is_expected.to be_valid
        end
      end

      context 'with invalid number of recipients' do
        let(:recipients) { 'foo@bar.com bar@foo.com bob@gitlab.com' }

        it { is_expected.not_to be_valid }

        it 'adds an error message' do
          integration.valid?

          expect(integration.errors).to contain_exactly('Recipients can\'t exceed 2')
        end

        context 'when integration is not active' do
          before do
            integration.active = false
          end

          it { is_expected.to be_valid }
        end
      end
    end
  end

  describe '.new' do
    context 'when properties is missing branches_to_be_notified' do
      subject { described_class.new(properties: {}) }

      it 'sets the default value to all' do
        expect(subject.branches_to_be_notified).to eq('all')
      end
    end

    context 'when branches_to_be_notified is already set' do
      subject { described_class.new(properties: { branches_to_be_notified: 'protected' }) }

      it 'does not overwrite it with the default value' do
        expect(subject.branches_to_be_notified).to eq('protected')
      end
    end
  end

  describe '.valid_recipients' do
    let(:recipients) { '<invalid> foobar valid@dup@asd Valid@recipient.com Dup@lica.te dup@lica.te Dup@Lica.te' }

    it 'removes invalid email addresses and removes duplicates by keeping the original capitalization' do
      expect(described_class.valid_recipients(recipients)).not_to contain_exactly('valid@dup@asd')
      expect(described_class.valid_recipients(recipients)).to contain_exactly('Valid@recipient.com', 'Dup@lica.te')
    end
  end
end
