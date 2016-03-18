require 'spec_helper'
require 'analytics'
require 'models/cookie_names'

module Analytics
  describe Analytics::Reporter do
    site_id = 5
    let(:client) { double(:client) }
    let(:reporter) { Analytics::Reporter.new(client, site_id) }
    let(:request) { double(:request) }

    it 'should report all parameters to piwik' do
      expect(request).to receive(:cookies).and_return({CookieNames::PIWIK_VISITOR_ID => 'VISITOR_ID'})
      expect(client).to receive(:report).with({
        'rec' => '1',
        'apiv' => '1',
        'idsite' => site_id,
        '_id' => 'VISITOR_ID'
      })
      reporter.report(request)
    end

    it 'should report all parameters except _id to piwik when no cookie' do
      expect(request).to receive(:cookies).and_return({})
      expect(client).to receive(:report).with({
        'rec' => '1',
        'apiv' => '1',
        'idsite' => site_id,
      })
      reporter.report(request)
    end
  end
end
