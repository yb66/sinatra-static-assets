require 'spec_helper'
require_relative "../lib/sinatra/static_assets.rb"

module Sinatra
module StaticAssets

require 'time'

describe Asset do
  let(:filename) { "image.jpg" }
  let(:asset_dir) { "app/public" }
  let(:fullpath) { File.join asset_dir, filename }
  let(:expected) { "image.jpg" }
  let(:time) { Time.parse "2013-05-01 18:18:02 0100" }
  before do
    File.stub(:"exists?").with(fullpath).and_return(true)
    File.stub(:mtime).with(fullpath).and_return(time)
  end
  subject(:asset){ Asset.new filename, asset_dir }
  it { should_not be_nil }
  it { should == expected }
  its(:fullpath) { should == fullpath }
  its(:timestamp) { should == time.to_i }
end

describe Tag do
  subject { tag }
  context "Given a group of options" do
    let(:tag) {
      Tag.new "link", 
              { :type => "text/css",
                :charset => "utf-8",
                :media => "projection",
                :rel => "stylesheet",
                :href => "/bar/stylesheets/winter.css"
              }
    }
    let(:expected) { %Q!<link charset="utf-8" href="/bar/stylesheets/winter.css" media="projection" rel="stylesheet" type="text/css" />! }
    it { should == expected }

    context "That include closed=false" do
        let(:tag) {
          Tag.new "link", 
                  { :type => "text/css",
                    :charset => "utf-8",
                    :media => "projection",
                    :rel => "stylesheet",
                    :href => "/bar/stylesheets/winter.css",
                    :closed => false
                  }
        }
      let(:expected) { %Q!<link charset="utf-8" href="/bar/stylesheets/winter.css" media="projection" rel="stylesheet" type="text/css">! }
      it { should == expected }
    end
  end
end


class FakeObject
  include Sinatra::StaticAssets::Private
  def uri( addr, absolute, script_tag )
    script_tag ? File.join( ENV["SCRIPT_NAME"], addr) : addr
  end
  def settings
    self
  end
  def public_folder
    "app/public"
  end
end
describe "Private methods" do
  let(:o) {
    # A double, I couldn't get RSpec's to work with this
    # probably because they're not well documented
    # hint hint RSpec team
    o = FakeObject.new
  }
  let(:script_name) { "/bar" }
  let(:fullpath) { File.join asset_dir, filename }
  let(:asset_dir) { "app/public/" }
  let(:time) { Time.parse "2013-05-01 18:18:02 0100" }
  before do
    ENV["SCRIPT_NAME"] = script_name
    File.stub(:"exists?").with(fullpath).and_return(true)
    File.stub(:mtime).with(fullpath).and_return(time)
  end
  context "Stylesheets" do
    let(:url) { "/stylesheets/winter.css" }
    let(:filename) { "/stylesheets/winter.css" }
    let(:expected) { %Q!<link charset="utf-8" href="/bar/stylesheets/winter.css?ts=1367428682" media="screen" rel="stylesheet" />! }
    subject { o.sss_stylesheet_tag url }
    it { should_not be_nil }
    it { should == expected }
  end
  context "Javascripts" do
    let(:url) { "/js/get_stuff.js" }
    let(:filename) { "/js/get_stuff.js" }
    let(:expected) { %Q!<script charset="utf-8" src="/bar/js/get_stuff.js?ts=1367428682"></script>! }
    subject { o.sss_javascript_tag url }
    it { should_not be_nil }
    it { should == expected }
  end
  context "Images" do
    let(:url) { "/images/foo.png" }
    let(:filename) { "/images/foo.png" }
    let(:expected) { %Q!<img src="/bar/images/foo.png?ts=1367428682" />! }
    subject { o.sss_image_tag url }
    it { should_not be_nil }
    it { should == expected }
  end
end

end # StaticAssets
end # Sinatra

describe "Using them with a Sinatra app" do
  include_context "All routes"
  let(:expected) { File.read File.expand_path(fixture_file, File.dirname(__FILE__)) }
  context "Main" do
    let(:fixture_file) { "./support/fixtures/main.txt" }
    before do
      get "/"
    end
    it_should_behave_like "Any route"
    subject { last_response.body }
    it { should == expected }
  end
  context "Sub" do
    let(:fixture_file) { "./support/fixtures/app2.txt" }
    before do
      get "/app2"
    end
    it_should_behave_like "Any route"
    subject { last_response.body }
    it { should == expected }
  end
end