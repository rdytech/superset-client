# frozen_string_literal: true

require "spec_helper"

# 0.5.3 was published unloadable: `require "superset"` raised
# `uninitialized constant EnumerateIt` while the whole suite was green, because
# spec_helper supplied the missing require itself and loaded lib/ by globbing
# rather than through the gem's entry point.
#
# These examples assert the gem's public surface is reachable from a plain
# `require "superset"`, with nothing else loaded on its behalf.
RSpec.describe "requiring the gem" do
  # Every constant here is resolved by lib/superset.rb's own requires. A dependency
  # that is declared in the gemspec but never required fails on the first one that
  # needs it, as EnumerateIt did.
  {
    "Superset"                              => -> { Superset },
    "Superset::VERSION"                     => -> { Superset::VERSION },
    "Superset::Client"                      => -> { Superset::Client },
    "Superset::GuestToken"                  => -> { Superset::GuestToken },
    "Superset::Authenticator"               => -> { Superset::Authenticator },
    "Superset::Display"                     => -> { Superset::Display },
    "Superset::Dashboard::List"             => -> { Superset::Dashboard::List },
    "Superset::Dashboard::Import"           => -> { Superset::Dashboard::Import },
    "Superset::Chart::List"                 => -> { Superset::Chart::List },
    "Superset::Dataset::List"               => -> { Superset::Dataset::List },
    "Superset::Services::DuplicateDashboard" => -> { Superset::Services::DuplicateDashboard },
    "Superset::Services::DashboardLoader"   => -> { Superset::Services::DashboardLoader },
    "ObjectType"                            => -> { ObjectType }
  }.each do |name, resolve|
    it "defines #{name}" do
      expect { resolve.call }.not_to raise_error
    end
  end

  # The activesupport, ostruct and enumerate_it requires in lib/superset.rb exist
  # only for these. Each one regressed into a load-time NameError at some point.
  it "has activesupport's core extensions loaded" do
    expect("x").to respond_to(:present?)
    expect({}).to respond_to(:with_indifferent_access)
    expect({}).to respond_to(:deep_symbolize_keys)
    expect("view_menu".humanize).to eq("View menu")
  end

  it "has OpenStruct loaded" do
    expect(defined?(OpenStruct)).to eq("constant")
  end

  it "has EnumerateIt loaded, with ObjectType usable" do
    expect(ObjectType).to be < EnumerateIt::Base
    expect(ObjectType.list).not_to be_empty
  end
end
