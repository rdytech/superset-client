require 'spec_helper'

RSpec.describe Superset::Dataset::WarmUpCache do
  subject { described_class.new(dashboard_id: dashboard_id) }
  let(:dashboard_id) { 1 }

  describe '.perform' do
		context "Dataset count is not considered" do
			let(:response) { nil }
			before do
				allow(subject).to receive(:response).and_return(response)
			end
			context 'when dashboard_id is not present' do
				let(:dashboard_id) { nil }

				it 'raises an error' do
					expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "dashboard_id must be present and must be an integer")
				end
			end

			context 'when dashboard_id is not an integer' do
				let(:dashboard_id) { 'string' }

				it 'raises an error' do
					expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "dashboard_id must be present and must be an integer")
				end
			end

			context 'when dashboard_id is an integer' do
				let(:response) { 'Dashboard warmed up' }

				it 'warms up the dashboard' do
					expect(subject.perform).to eq response
				end
			end
		end

    context 'when dashboard has multiple datasets' do
			let(:dataset_details) do
				[
					{"name"=>"client database 1", "datasource_name"=>"datasource 101"},
					{"name"=>"client database 2", "datasource_name"=>"datasource 102"},
			 	]
			end
			let(:api_response) { "Dataset warmed up" }
			before do
				allow(subject).to receive(:fetch_dataset_details).with(dashboard_id) { dataset_details } 
				allow(subject).to receive(:api_response).and_return(api_response)
			end
			it 'warms up both the dataset' do
				subject.response
				expect(subject).to have_received(:api_response).twice
			end
    end
  end
end
