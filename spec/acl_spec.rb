require 'spec_helper'

include OSX

def make_dir_with_two_aces
  system(
    "
      rm -Rf 'spec/fixtures/dir_with_two_aces';
      mkdir -p 'spec/fixtures/dir_with_two_aces';
      chmod +a 'group:staff allow read' 'spec/fixtures/dir_with_two_aces';
      chmod +a 'group:_www allow read' 'spec/fixtures/dir_with_two_aces';
    "
  )
end

describe ACL do
  it 'has a version number' do
    expect(ACL::VERSION).not_to be nil
  end

  it 'can be intantiated from a path' do
    expect(ACL.of("/")).to be_kind_of(ACL)
    expect(ACL.of("/tmp").path).to eq("/tmp")
  end

  it "can read lines of acl entries" do
    expect(ACL.of("/").entry_lines).to be_kind_of(Array)
    make_dir_with_two_aces
    expect(ACL.of("spec/fixtures/dir_with_two_aces").entry_lines.length).to eq(2)
    expect(ACL.of("spec/fixtures/dir_with_two_aces").entry_lines.first).to eq("group:ABCDEFAB-CDEF-ABCD-EFAB-CDEF00000046:_www:70:allow:read")
    expect(ACL.of("spec/fixtures/dir_with_two_aces").entry_lines.last).to eq("group:ABCDEFAB-CDEF-ABCD-EFAB-CDEF00000014:staff:20:allow:read")
  end

  describe "its entries" do
    it 'is an array' do
      expect(ACL.of("/").entries).to be_kind_of(Array)
    end

    it 'returns entry instances' do
      make_dir_with_two_aces
      entries = ACL.of("spec/fixtures/dir_with_two_aces").entries
      expect(entries.length).to eq(2)
      expect(entries.first).to be_kind_of(ACL_Entry)
    end
  end
end
