require 'spec_helper'

RSpec.describe Superset::Database::List do
  subject { described_class.new }
  let(:response) do
    { 'result' =>
      [
        {
          id: 1,
          database_name: 'Test 1',
          backend: 'postgres',
          expose_in_sqllab: 'true'
        },
        {
          id: 2,
          database_name: 'Test 2',
          backend: 'mysql',
          expose_in_sqllab: 'false'
        }
      ]
    }
  end
  let(:default_query_params) { "page:0,page_size:100,order_column:changed_on,order_direction:desc" }

  describe '#rows' do
    before do
      allow(subject).to receive(:response).and_return(response)
    end

    specify do
      expect(subject.rows).to match_array(
        [
          ['1', "Test 1", "postgres", "true"],
          ['2', 'Test 2', 'mysql', "false"]
        ]
      )
    end
  end

  describe '#query_params' do
    context 'for pagination' do
      context 'with defaults' do
        specify do
          expect(subject.query_params).to eq(default_query_params)
        end
      end

      context 'with specifiec page' do
        subject { described_class.new(page_num: 5) }

        specify do
          expect(subject.query_params).to eq(default_query_params.gsub('page:0', 'page:5'))
        end
      end
    end

    context 'with title_contains filters' do
      subject { described_class.new(title_contains: 'acme') }

      specify do
        expect(subject.query_params).to eq("filters:!((col:database_name,opr:ct,value:'acme')),#{default_query_params}")
      end
    end

    context 'with uuid_equals filters' do
      subject { described_class.new(uuid_equals: '123') }

      specify do
        expect(subject.query_params).to eq("filters:!((col:uuid,opr:eq,value:'123')),#{default_query_params}")
      end
    end
  end

  describe '#response' do
    context 'with invalid parameters' do
      context 'when title_contains is not a string' do
        subject { described_class.new(title_contains: ['test']) }

        specify do
          expect { subject.response }.to raise_error(Superset::Request::InvalidParameterError, 'title_contains must be a String type')
        end
      end

      context 'when uuid_equals is not a string' do
        subject { described_class.new(uuid_equals: 1) }

        specify do
          expect { subject.response }.to raise_error(Superset::Request::InvalidParameterError, 'uuid_equals must be a String type')
        end
      end
    end
  end
end
