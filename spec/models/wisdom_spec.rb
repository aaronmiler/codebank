require "spec_helper"
require "base64"
describe "Wisdom" do
  before(:all) do
    @markdown = "# This is the title\n<!--- desc --->\nHere is the description blah\n<!--- end_desc --->\n```\nthis = []\nthis << 'potato'\n```\n#### Tags\n<!--- tags --->\ntag:this_is_tag tag:potato\n<!--- end_tags --->"
  end
  it "should respond to seperate" do
    wisdom = Wisdom.new
    wisdom.markdown = @markdown
    wisdom.seperate()
  end
  it "should seperate markdown correctly" do
    wisdom = Wisdom.new
    wisdom.markdown = @markdown
    wisdom.seperate()
    wisdom.title.should == "This Is The Title"
    wisdom.description.should == "Here is the description blah"
    wisdom.content.should == "this = []\nthis << 'potato'"
    wisdom.tags.should == "This Is Tag, Potato"
  end
  it "should assign the contents" do
    wisdom = Wisdom.new('topic' => "ruby", 'title' => "Title", 'description' => "description", 'content' => "this = []", 'tags' => "tag one,tag two")
    wisdom.title.should == "Title"
    wisdom.topic.should == "ruby"
    wisdom.description.should == "description"
    wisdom.content.should == "this = []"
    wisdom.tags.should == "tag:tag_one tag:tag_two"
  end
  it "should set the original title in prepare_for_save" do
    wisdom = Wisdom.new(
      'topic' => 'CSS',
      'title' => 'How to Potato',
      'tags' => '',
      'content' => '')
    wisdom.prepare_for_save({:original_title => 'html/how_to_potato.md'})
    wisdom.title.should_not be wisdom.original_title
  end
  it "should decode markdown with parse call" do
    wisdom = Wisdom.new()
    wisdom.parse(Base64.encode64(@markdown))
    wisdom.markdown.should == @markdown
  end
end