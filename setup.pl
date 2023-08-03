use strict;
use warnings;
use Term::ANSIColor;

sub info {  return "[" . colored("INFO", 'green') . "]:    "; }
sub error { return "[" . colored("ERROR", 'red')  . "]:   "; }

sub create_env_file {
    die error() . "Couldn't find docker/ dir." unless (-d "docker");
    my $filename = "docker/.env";
    if (-e $filename) {
        print info . "Found file $filename, skipping\n";
        return;
    }

    my $username = $ENV{LOGNAME} || $ENV{USERNAME} || $ENV{USER};
    my $uid = getpwnam($username);
    my $gid = getgrnam($username);

    my $str = "MY_UID=$uid\nMY_GID=$gid\nMY_USER=$username\n";

    open (FH, '>', $filename) or die error() . "Failed to create file \"$filename\". Error is $!.\n";
    print FH $str;
    close(FH);
    
    print info . "Successfully created file $filename\n";
}

sub is_folder_empty {
    my $dirname = shift;
    opendir(my $dh, $dirname) or die error() . "Not a directory: $dirname";
    my $result = scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0;
    closedir $dh;

    return $result;
}

sub download_deps {
    my $depsdir = "deps"; 
    unless(-d $depsdir) {
        mkdir $depsdir or die "Failed to create directory \"$depsdir\". Error is $!.\n"
    }

    my %branches = (
        'libsodium'      => "stable", 
    );

    my %pathes = ( 
        'libOTe'         => "https://github.com/osu-crypto/libOTe.git", 
        'relic'          => "https://github.com/relic-toolkit/relic.git",
        'coproto'        => "https://github.com/Visa-Research/coproto.git",
        'macoro'         => "https://github.com/ladnir/macoro.git",
        'variant-lite'   => "https://github.com/martinmoene/variant-lite.git",
        'optional-lite'  => "https://github.com/martinmoene/optional-lite.git",
        'function2'      => "https://github.com/Naios/function2.git",
        'bitpolymul'     => "https://github.com/ladnir/bitpolymul.git",
        'libdivide'      => "https://github.com/ridiculousfish/libdivide.git",
        'span-lite'      => "https://github.com/martinmoene/span-lite.git",
        # 'libsodium'      => "https://github.com/jedisct1/libsodium.git", 
    );

    for(keys %pathes){
        my $key = $_;
        my $url = $pathes{$_};
        my $targetdir = "$depsdir/$key";

        unless (-d $targetdir) {
            mkdir $targetdir or die error() . "Failed to create directory \"$targetdir\". Error is $!.\n"
        }

        next unless is_folder_empty($targetdir);

        print info . "Cloning \'$key\'.\n";

        if (exists $branches{$key}) {
            system("git", "clone", "--recurse-submodules",  "--depth=1", "--branch", $branches{$key}, $url, $targetdir) == 0
                or die error() . "Failed to clone $key.";
        } else {
            system("git", "clone", "--recurse-submodules",  "--depth=1", $url, $targetdir) == 0
                or die error() . "Failed to clone $key.";
        }
        
        print info . "Successfully cloned \'$key\'.\n";
    }
}

sub quirks {
    sub disable_macoro_tests {
        my $filename = "deps/macoro/tests/CMakeLists.txt";
        if (-e $filename) {
            my $str = "message(STATUS \"MACORO Tests are disabled.\")";
            open (my $fh, '>', $filename) or return; # error() . "Failed to create file \"$filename\". Error is $!.\n";
            print $fh $str;
            close($fh);
        }
    }
    sub disable_macoro_frontend {
        my $filename = "deps/macoro/frontend/CMakeLists.txt";
        if (-e $filename) {
            my $str = "message(STATUS \"MACORO Frontend are disabled.\")";
            open (my $fh, '>', $filename) or return; # error() . "Failed to create file \"$filename\". Error is $!.\n";
            print $fh $str;
            close($fh);
        }
    }
    sub checkout_bit_poly_mul_tag {
        my $tag = "ba351330f397ce758757f7858d5c479f35a340b4";
        system("cd deps/bitpolymul;git checkout $tag >/dev/null 2>&1");
    }
    sub fix_includes {
        my %includes = ( 'deps/libOTe/cryptoTools/cryptoTools/Crypto/AES.h'         =>  "utility",
                         'deps/libOTe/cryptoTools/cryptoTools/Common/Aligned.h'     =>  "utility",
                         'deps/macoro/macoro/detail/when_all_task.h'                =>  "utility",
                         'deps/libOTe/cryptoTools/cryptoTools/Common/Timer.h'       =>  "stdexcept", );
        
        for(keys %includes){
            my $cpp_file = $_;
            
            my $header = "<$includes{$_}>";
            my $line_to_insert = "#include $header\n";
            
            my @file_contents = ();
            my $skip = 0;

            open(my $in, '<', $cpp_file) or die error() . "Failed to open file \"$cpp_file\" for reading. Error is $!.\n";
            while ( <$in> ) {
                if ($_ =~ /$header/) {
                    $skip = 1;
                    last;
                }
                
                push @file_contents, $_;
            }
            close($in);
            next if $skip;

            my $START = 0;
            my $FOUND_INCLUDES = 1;
            my $DONE = 2;

            my $state_machine = $START;

            open(my $out, '>', $cpp_file) or die error() . "Failed to open file \"$cpp_file\" for writing. Error is $!.\n";
            foreach ( @file_contents ) {
                if ($state_machine == $START) {
                    $state_machine = $FOUND_INCLUDES if $_ =~ /#include/;
                } elsif ($state_machine == $FOUND_INCLUDES) {
                    if ($_ !~ /#include/) {
                        $state_machine = $DONE;
                        print $out $line_to_insert;
                    }
                }

                print $out $_;
            }
            close($out);
        }

    }
    sub fix_symbols {
        my %headers = (
            'deps/libOTe/thirdparty/SimplestOT/fe25519.h'       =>  'fe25519_invert',
            'deps/libOTe/thirdparty/SimplestOT/ge25519.h'       =>  'ge25519_add',
            'deps/libOTe/thirdparty/SimplestOT/ge25519.h'       =>  'ge25519_p1p1_to_p2',
            'deps/libOTe/thirdparty/SimplestOT/ge25519.h'       =>  'ge25519_p1p1_to_p3',
            'deps/libOTe/thirdparty/SimplestOT/ge25519.h'       =>  'ge25519_scalarmult',
            'deps/libOTe/thirdparty/SimplestOT/ge25519.h'       =>  'ge25519_scalarmult_base',
        );

        ###############################################################################################
        #  dirty! HACK
        ###############################################################################################
        
        for(keys %headers){
            my $header_file = $_;

            my $symbol = $headers{$_};
            my $new_symbol = "simplest_ot_$symbol";
            
            my @file_contents = ();
            my $skip = 0;

            open(my $in, '<', $header_file) or die error() . "Failed to open file \"$header_file\" for reading. Error is $!.\n";
            while ( <$in> ) {
                if ($_ =~ /$new_symbol\(/) {
                    $skip = 1;
                    last;
                }
                
                push @file_contents, $_;
            }
            close($in);
            next if $skip;

            open(my $out, '>', $header_file) or die error() . "Failed to open file \"$header_file\" for writing. Error is $!.\n";
            foreach ( @file_contents ) {
                if ($_ =~ /$symbol/) {
                    print $out "#define $symbol $new_symbol\n";
                }

                print $out $_;
            }
            close($out);
        }
    }
    sub fix_faulty_test {
        my $cpp_file = "deps/libOTe/libOTe_Tests/ExConvCode_Tests.cpp";

        my $call_to_disable = "code.accumulate<block, u8>";
        
        my @file_contents = ();
        my $do_modify = 1;

        open(my $in, '<', $cpp_file) or die error() . "Failed to open file \"$cpp_file\" for reading. Error is $!.\n";
        while ( <$in> ) {
            push @file_contents, $_;
            if ($_ =~ /#if 0/) {
                $do_modify = 0;
                last;
            }
        }
        close($in);

        if ($do_modify) {
            my $disable_current_line = 0;

            open(my $out, '>', $cpp_file) or die error() . "Failed to open file \"$cpp_file\" for writing. Error is $!.\n";
            foreach ( @file_contents ) {
                if ($_ =~ /$call_to_disable/) {
                    print $out "#if 0\n";
                    $disable_current_line = 1;
                }

                print $out $_;
                if ($disable_current_line) {
                    if ($_ =~ /;/) {
                        print $out "#endif\n";
                        $disable_current_line = 0;
                    }
                }
            }
            close($out);
        }
    }

    disable_macoro_tests();
    disable_macoro_frontend();
    checkout_bit_poly_mul_tag();
    fix_includes();
    # fix_symbols();
    fix_faulty_test();
}

sub main_sub {
    create_env_file();
    download_deps();

    quirks();

    print info . "Done.\n";
}

main_sub();
