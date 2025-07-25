require "../spec_helper"

module Ameba
  describe Source do
    describe ".new" do
      it "allows to create a source by code and path" do
        source = Source.new "code", "path"
        source.path.should eq "path"
        source.code.should eq "code"
        source.lines.should eq ["code"]
      end
    end

    describe "#fullpath" do
      it "returns a relative path of the source" do
        source = Source.new path: "./source_spec.cr"
        source.fullpath.should contain "source_spec.cr"
      end

      it "returns fullpath if path is blank" do
        source = Source.new
        source.fullpath.should_not be_nil
      end
    end

    describe "#matches_path?" do
      it "returns true if source's path is matched" do
        source = Source.new path: "source.cr"
        source.matches_path?("source.cr").should be_true
      end

      it "returns false if source's path is not matched" do
        source = Source.new path: "source.cr"
        source.matches_path?("new_source.cr").should be_false
      end
    end
  end
end
