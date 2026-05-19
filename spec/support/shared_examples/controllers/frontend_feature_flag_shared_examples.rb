# frozen_string_literal: true

RSpec.shared_examples 'pushes frontend feature flag' do |feature_name|
  let(:make_request) { raise NotImplementedError }
  let(:feature_args) { [] }
  let(:feature_kwargs) { {} }

  it "pushes #{feature_name} feature flag to the frontend" do
    with_controller do |controller|
      allow(controller).to receive(:push_frontend_feature_flag)

      make_request

      expect(controller).to have_received(:push_frontend_feature_flag)
        .with(feature_name, *feature_args, **feature_kwargs)
    end
  end

  def with_controller(&_block)
    if RSpec.current_example.metadata[:type] == :controller
      yield(controller)
    else
      allow_next_instance_of(described_class) do |ctrl|
        yield(ctrl)
      end
    end
  end
end
