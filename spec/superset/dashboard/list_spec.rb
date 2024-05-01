require 'spec_helper'

RSpec.describe Superset::Dashboard::List do
  subject { described_class.new }
  let(:superset_host) { 'https://test.superset.host.com' }
  let(:result) do
    [
      {
        id: 36,
        dashboard_title: 'Test Embedded 2',
        status: 'published',
        url: '/superset/dashboard/36/'
      },
      {
        id: 15,
        dashboard_title: 'Test Embedded 1',
        status: 'published',
        url: '/superset/dashboard/15/'
      }
    ]
  end

  before do
    allow(subject).to receive(:result).and_return(result)
    allow(subject).to receive(:superset_host).and_return(superset_host)
    allow(subject).to receive(:retrieve_schemas).with(36).and_return( { schemas: ['acme'] } )
    allow(subject).to receive(:retrieve_schemas).with(15).and_return( { schemas: ['coyote'] } )
    allow(subject).to receive(:retrieve_embedded_details).with(36).and_return(
      { allowed_embedded_domains: ["https://test-acme.io/"], uuid: 'some-uuid-for-36' } )
    allow(subject).to receive(:retrieve_embedded_details).with(15).and_return(
      { allowed_embedded_domains: [], uuid: 'some-uuid-for-15' } )
  end

  describe '#all' do
    it 'returns an array of OpenStruct objects with the correct attributes' do
      dashboards = subject.all
      expect(dashboards).to be_an(Array)
      expect(dashboards.length).to eq(result.length)
      expect(dashboards.first).to be_an(OpenStruct)
      expect(dashboards.first.id).to eq(result.first[:id])
      expect(dashboards.first.dashboard_title).to eq(result.first[:dashboard_title])
      expect(dashboards.first.status).to eq(result.first[:status])
      expect(dashboards.first.url).to eq(result.first[:url])
      expect(dashboards.first.schemas).to eq(['acme'])
      expect(dashboards.first.allowed_embedded_domains).to eq(['https://test-acme.io/'])
      expect(dashboards.first.uuid).to eq('some-uuid-for-36')
    end
  end

  describe '#rows' do
    specify do
      expect(subject.rows).to match_array(
        [
          [15, "Test Embedded 1", "published", "https://test.superset.host.com/superset/dashboard/15/"],
          [36, 'Test Embedded 2', 'published', "https://test.superset.host.com/superset/dashboard/36/"]
        ]
      )
    end
  end

  describe '#query_params' do
    context 'for pagination' do
      context 'with defaults' do
        specify do
          expect(subject.query_params).to eq("page:0,page_size:100")
        end
      end

      context 'with specifiec page' do
        subject { described_class.new(page_num: 5) }

        specify do
          expect(subject.query_params).to eq("page:5,page_size:100")
        end
      end
    end

    context 'with title_contains filters' do
      subject { described_class.new(title_contains: 'acme') }

      specify do
        expect(subject.query_params).to eq("filters:!((col:dashboard_title,opr:ct,value:'acme')),page:0,page_size:100")
      end
    end

    context 'with multiple filter set' do
      subject { described_class.new(title_contains: 'birth', tags_equal: ['template']) }

      specify do
        expect(subject.query_params).to eq(
          "filters:!(" \
          "(col:dashboard_title,opr:ct,value:'birth')," \
          "(col:tags,opr:dashboard_tags,value:'template')" \
          "),page:0,page_size:100")
      end
    end

    context 'with multiple filter set and multiple tags' do
      subject { described_class.new(page_num: 3, title_contains: 'birth', tags_equal: ['template', 'client:acme', 'product:turbo-charged-feet']) }

      specify do
        expect(subject.query_params).to eq(
          "filters:!(" \
          "(col:dashboard_title,opr:ct,value:'birth')," \
          "(col:tags,opr:dashboard_tags,value:'template')," \
          "(col:tags,opr:dashboard_tags,value:'client:acme')," \
          "(col:tags,opr:dashboard_tags,value:'product:turbo-charged-feet')" \
          "),page:3,page_size:100")
      end
    end


  end

end
