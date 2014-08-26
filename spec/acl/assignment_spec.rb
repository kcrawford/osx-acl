require 'spec_helper.rb'

include OSX
require 'acl/assignment'

def sample_assignment
  ACL::Assignment.new(["group", "ABCDEFAB-CDEF-ABCD-EFAB-CDEF00000046", "_www", "70"])
end

describe ACL::Assignment do
  describe '.new' do
    it "instantiates with array of string components" do
      sample_assignment
    end
  end

  it "has a type" do
    expect(sample_assignment.type).to eq("group")
  end

  it "has a uuid" do
    expect(sample_assignment.uuid).to eq("ABCDEFAB-CDEF-ABCD-EFAB-CDEF00000046")
  end

  it "has a name" do
    expect(sample_assignment.name).to eq("_www")
  end

  it "has an id" do
    expect(sample_assignment.id).to eq("70")
  end

  describe "#orphan?" do
    it "is true when name is blank" do
      orphaned_assignment = sample_assignment
      orphaned_assignment.name = ""
      expect(orphaned_assignment.orphan?).to eq(true)
    end
    it "is false when name is not blank" do
      expect(sample_assignment.orphan?).to eq(false)
    end
  end
end
