require 'spec_helper'
require 'helm_template_helper'

describe 'example configurations' do
  root = File.join(__dir__, '..', '..')

  Dir["#{root}/examples/**/*.{yaml,yml}"].each do |path|
    it "renders #{path.delete_prefix(root).delete_prefix('/')}", :aggregate_failures do
      t = HelmTemplate.new(HelmTemplate.defaults, 'gitlab-examples-test', "-f #{path}")

      expect(t.exit_code.to_i).to eq(0), "helm template generated error for #{path}"
      expect(t.stdout).to include('name: gitlab-examples-test')
      expect(t.stderr).to be_empty
    end
  end
end
