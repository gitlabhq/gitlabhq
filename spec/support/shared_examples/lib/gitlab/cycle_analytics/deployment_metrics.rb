# frozen_string_literal: true

RSpec.shared_examples 'deployment metrics examples' do
  include CycleAnalyticsHelpers

  describe "#deploys" do
    subject { stage_summary.third }

    context 'when from date is given' do
      before do
        travel_to(5.days.ago) { create_deployment(project: project) }
        create_deployment(project: project)
      end

      it "finds the number of deploys made created after the 'from date'" do
        expect(subject[:value]).to eq('1')
      end

      it 'returns the localized title' do
        Gitlab::I18n.with_locale(:ru) do
          expect(subject[:title]).to eq(n_('Deploy', 'Deploys', 1))
        end
      end
    end

    it "doesn't find commits from other projects" do
      travel_to(5.days.from_now) do
        create_deployment(project: create(:project, :repository))
      end

      expect(subject[:value]).to eq('-')
    end

    context 'when `to` parameter is given' do
      before do
        travel_to(5.days.ago) { create_deployment(project: project) }
        travel_to(5.days.from_now) { create_deployment(project: project) }
      end

      it "doesn't find any record" do
        options[:to] = Time.now

        expect(subject[:value]).to eq('-')
      end

      it "finds records created between `from` and `to` range" do
        options[:from] = 10.days.ago
        options[:to] = 10.days.from_now

        expect(subject[:value]).to eq('2')
      end
    end
  end

  describe '#deployment_frequency' do
    subject { stage_summary.fourth[:value] }

    before do
      travel_to(5.days.ago) { create_deployment(project: project) }
    end

    it 'includes the unit: `/day`' do
      expect(stage_summary.fourth[:unit]).to eq _('/day')
    end

    it 'returns 2 digits precision for small numbers' do
      options[:from] = 90.days.ago

      expect(subject).to eq('0.01')
    end

    it 'returns `-` when there were no deploys' do
      options[:from] = 4.days.ago

      # 0 deployment in the last 4 days
      expect(subject).to eq('-')
    end

    context 'when `to` is nil' do
      it 'includes range until now' do
        options[:from] = 6.days.ago
        options[:to] = nil

        # 1 deployment over 7 days
        expect(subject).to eq('0.14')
      end
    end

    context 'when `to` is given' do
      before do
        travel_to(5.days.from_now) { create_deployment(project: project, finished_at: Time.zone.now) }
      end

      it 'finds records created between `from` and `to` range' do
        options[:from] = 10.days.ago
        options[:to] = 10.days.from_now

        # 2 deployments over 20 days
        expect(subject).to eq('0.1')
      end

      context 'when `from` and `to` are within a day' do
        it 'returns the number of deployments made on that day' do
          freeze_time do
            create_deployment(project: project, finished_at: Time.current)
            options[:from] = Time.current.yesterday.beginning_of_day
            options[:to] = Time.current.end_of_day

            expect(subject).to eq('0.5')
          end
        end
      end
    end
  end
end
