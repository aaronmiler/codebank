require "spec_helper"
require "base64"
describe "Wisdom" do
  it "should respond to seperate" do
    wisdom = Wisdom.new
    markdown = "# This is the title\n\nHere is the description blah\n\n```\nthis = []\nthis << 'potato'\n``` \n\n#### Tags\ntag:this_is_tag tag:potato\n"
    wisdom.seperate(Base64.encode64(markdown))
  end
  it "should seperate markdown correctly" do
    wisdom = Wisdom.new
    markdown = "# This is the title\n\nHere is the description blah\n\n```\nthis = []\nthis << 'potato'\n``` \n\n#### Tags\ntag:this_is_tag tag:potato\n"
    wisdom.seperate(Base64.encode64(markdown))
    wisdom.title.should == "This Is The Title"
    wisdom.description.should == "Here is the description blah"
    wisdom.content.should == "this = []\nthis << 'potato'"
    wisdom.tags.should == "This Is Tag, Potato"
  end
  it "should assign the contents" do
    contents = {'topic' => "ruby", 'title' => "Title", 'description' => "description", 'content' => "this = []", 'tags' => "tag one,tag two"}
    wisdom = Wisdom.new
    wisdom.set_contents(contents)
    wisdom.title.should == "Title"
    wisdom.topic.should == "ruby"
    wisdom.description.should == "description"
    wisdom.content.should == "this = []"
    wisdom.tags.should == "tag:tag_one tag:tag_two"
  end
end