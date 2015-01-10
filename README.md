# osx-acl

Tool and Ruby Library for managing ACLs on OS X

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'osx-acl'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install osx-acl

## Building

`
rake build
fpm -s gem -t osxpkg --osxpkg-identifier-prefix org.rubygems.kcrawford
pkg/osx-acl-1.x.gem`

## Usage

From the acl_tool

```
Usage: /usr/bin/acl_tool [OPTIONS] path

Options
        --dry-run                    outputs what would be done without modifying ACLs
        --exclude x,y,z              users to exclude from --remove-user-entries
        --remove-orphans             removes orphaned acl entries
        --remove-user-entries        removes user acl entries
        --report                     report existing ACLs
        --version                    outputs version information for this tool
        --help                       outputs help information for this tool
```

From ruby
```
>> require 'acl'
=> true
>> acl = OSX::ACL.of("tmp")
=> #<OSX::ACL:0x007f92eaabc578 @path="tmp">
>> acl.entries
=> [#<OSX::ACL::Entry:0x007f92eaaf7510 @components=["user", "FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000046", "_www", "70", "allow", "read"]>]
>> ace = acl.entries.first
=> #<OSX::ACL::Entry:0x007f92eaaf7510 @components=["user", "FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000046", "_www", "70", "allow", "read"]>
>> ace.assignment
=> #<OSX::ACL::Assignment:0x007f92ea2a0060 @type="user", @uuid="FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000046", @name="_www", @id="70">
>> ace.assignment.type
=> "user"
>> ace.assignment.name
=> "_www"
>> acl.remove_entry_at_index(0)
chmod -a# 0 tmp # user:FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000046:_www:70:allow:read
=> true
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/osx-acl/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
