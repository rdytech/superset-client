require 'spec_helper'

# rubyzip is only used by the dashboard import/export feature, which is loaded
# lazily (require 'zip' happens inside those methods, not at gem load). Keeping
# it OUT of the runtime dependencies means consumers that only embed / read /
# write (Neptune, Ready STA, Ready Apprentice) don't inherit the gem's rubyzip
# >= 3 pin, which otherwise cascades roo/docx major upgrades on them (NEP-21211).
RSpec.describe 'superset.gemspec dependencies' do
  let(:gemspec) do
    Gem::Specification.load(File.expand_path('../../superset.gemspec', __dir__))
  end

  it 'does not list rubyzip as a runtime dependency' do
    runtime = gemspec.runtime_dependencies.map(&:name)
    expect(runtime).not_to include('rubyzip')
  end

  it 'keeps rubyzip as a development dependency (import/export still tested here)' do
    dev = gemspec.development_dependencies.map(&:name)
    expect(dev).to include('rubyzip')
  end
end
