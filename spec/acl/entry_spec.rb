require 'spec_helper.rb'

include OSX
require 'acl/entry'

def valid_acl
  ACL::Entry.from_text("group:ABCDEFAB-CDEF-ABCD-EFAB-CDEF00000046:_www:70:allow,inherited:read,write")
end

describe ACL::Entry do
  describe '.from_text' do
    it "instantiates with text" do
      expect(ACL::Entry.from_text("doh")).to be_kind_of(ACL::Entry)
    end
  end

  it "has an assignment" do
    expect(valid_acl).to respond_to(:assignment)
  end

  it "has rules" do
    expect(valid_acl.rules).to eq(["allow", "inherited"])
  end

  it "has permissions" do
    expect(valid_acl.permissions).to eq(["read","write"])
  end
end
