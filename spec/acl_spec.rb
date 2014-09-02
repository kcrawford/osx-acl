require 'spec_helper'

include OSX
DIR_WITH_VALID_ACES = 'tmp/dir_with_two_aces'
DIR_WITH_ORPHAN_ACES = 'tmp/dir_with_orphan_aces'

def make_dir_with_two_aces
  puts "creating dir with two aces..."
  system(
    "
      rm -Rf 'tmp/dir_with_two_aces';
      mkdir -p 'tmp/dir_with_two_aces';
      chmod +a 'group:staff allow read' 'tmp/dir_with_two_aces';
      chmod +a 'group:_www allow read' 'tmp/dir_with_two_aces';
    "
  )
end

def create_acl_with_orphans
  make_dir_with_two_aces
  puts "creating invalid aces..."
  system(
    "
      rm -Rf '#{DIR_WITH_ORPHAN_ACES}';
      mv 'tmp/dir_with_two_aces' 'tmp/dir_with_orphan_aces';
      sudo dscl . -create /Users/_acl_orphan_user;
      sudo dscl . -create /Users/_acl_orphan_user PrimaryGroupID 20;
      sudo dscl . -create /Users/_acl_orphan_user UserShell /bin/false;
      sudo dscl . -create /Users/_acl_orphan_user NFSHomeDirectory /dev/null;
      sudo dscl . -create /Users/_acl_orphan_user RealName acl_orphan_user;
      sudo dscl . -create /Users/_acl_orphan_user UniqueID 1020;
      chmod +a 'user:_acl_orphan_user allow read' 'tmp/dir_with_orphan_aces';
      chmod +a# 3 'user:_acl_orphan_user deny write' 'tmp/dir_with_orphan_aces';
      sudo dscl . -delete /Users/_acl_orphan_user;
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
    expect(ACL.of("tmp/dir_with_two_aces").entry_lines.length).to eq(2)
    expect(ACL.of("tmp/dir_with_two_aces").entry_lines.first).to eq("group:ABCDEFAB-CDEF-ABCD-EFAB-CDEF00000046:_www:70:allow:read")
    expect(ACL.of("tmp/dir_with_two_aces").entry_lines.last).to eq("group:ABCDEFAB-CDEF-ABCD-EFAB-CDEF00000014:staff:20:allow:read")
  end

  describe "its entries" do
    it 'is an array' do
      expect(ACL.of("/").entries).to be_kind_of(Array)
    end

    it 'returns entry instances' do
      make_dir_with_two_aces
      entries = ACL.of("tmp/dir_with_two_aces").entries
      expect(entries.length).to eq(2)
      expect(entries.first).to be_kind_of(ACL::Entry)
    end

    it "handles symlinks" do
      # create a symlink that points nowhere so File.open fails
      system("ln", "-sf", "/tmp/.would_not_exist_ever_ever", "tmp/symlink")
      expect(ACL.of("tmp/symlink").entries.length).to eq(0)
    end
  end

  describe "#remove_orphans!" do
    it "returns number of orphans removed" do
      create_acl_with_orphans
      expect(ACL.of(DIR_WITH_ORPHAN_ACES).remove_orphans!).to eq(2)
      make_dir_with_two_aces
      expect(ACL.of(DIR_WITH_VALID_ACES).remove_orphans!).to eq(0)
    end
    it "only removes orphans" do
      create_acl_with_orphans
      ACL.of(DIR_WITH_ORPHAN_ACES).remove_orphans!
      expect(ACL.of(DIR_WITH_ORPHAN_ACES).entries.length).to eq(2)
      expect(ACL.of(DIR_WITH_ORPHAN_ACES).orphans.length).to eq(0)
    end
    it "preserves the order of remaining aces" do
      create_acl_with_orphans
      ACL.of(DIR_WITH_ORPHAN_ACES).remove_orphans!
      expect(ACL.of(DIR_WITH_ORPHAN_ACES).entries.first.assignment.name).to eq("_www")
      expect(ACL.of(DIR_WITH_ORPHAN_ACES).entries.last.assignment.name).to eq("staff")
    end
    it "does nothing if environment variable is set to NOOP" do
      create_acl_with_orphans
      ENV['OSX_ACL_NOOP'] = 'yes'
      acl_with_orphans = ACL.of(DIR_WITH_ORPHAN_ACES)
      acl_with_orphans.remove_orphans!
      expect(acl_with_orphans.remove_orphans!).to eq(2)
    end
  end
end

