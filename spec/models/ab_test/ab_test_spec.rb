require 'spec_helper'
require 'models/ab_test/ab_test'
require 'models/ab_test/experiment'

module AbTest
  describe AbTest do
    context '#alternative_name_for_experiment' do
      it 'should return the default when no experiment exists' do
        stub_const('AB_TESTS', {})
        alternative_name = subject.alternative_name_for_experiment('missing_experiment', 'alternative', 'default')
        expect(alternative_name).to eq('default')
      end

      it 'should return alternative name' do
        alternatives = { 'logos' => { 'alternatives' => [{ 'name' => 'yes', 'percent' => 75 }] } }
        stub_const('AB_TESTS', 'logos' => Experiment.new(alternatives))
        alternative_name = subject.alternative_name_for_experiment('logos', 'logos_yes', 'default')
        expect(alternative_name).to eq('logos_yes')
      end

      it 'should return first alternative name when given invalid alternative' do
        alternatives = { 'logos' => { 'alternatives' => [{ 'name' => 'yes', 'percent' => 75 }] } }
        stub_const('AB_TESTS', 'logos' => Experiment.new(alternatives))
        alternative_name = subject.alternative_name_for_experiment('logos', 'invalid', 'default')
        expect(alternative_name).to eq('logos_yes')
      end
    end

    context '#report' do
      let(:analytics_reporter) { double(:analytics_reporter) }

      it 'should report to piwik if there are multiple alternatives' do
        alternatives = { 'logos' => { 'alternatives' => [{ 'name' => 'yes', 'percent' => 75 }, { 'name' => 'no', 'percent' => 25 }] } }
        stub_const('AB_TESTS', 'logos' => Experiment.new(alternatives))
        stub_const('ANALYTICS_REPORTER', analytics_reporter)
        expect(analytics_reporter).to receive(:report_custom_variable)
        subject.report('logos', 'logos_yes', double(:request))
      end

      it 'should not report to piwik if there is a single alternative' do
        alternatives = { 'logos' => { 'alternatives' => [{ 'name' => 'yes', 'percent' => 75 }] } }
        stub_const('AB_TESTS', 'logos' => Experiment.new(alternatives))
        stub_const('ANALYTICS_REPORTER', analytics_reporter)
        expect(analytics_reporter).to_not receive(:report_custom_variable)
        subject.report('logos', 'logos_yes', double(:request))
      end
    end
  end
end
