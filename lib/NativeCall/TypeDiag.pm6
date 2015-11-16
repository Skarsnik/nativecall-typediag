use NativeCall;
use File::Temp;

module NativeCall::TypeDiag {
  my $c_header;
  
  sub diag-cstructs(:@cheaders, :@clibs = (), :%types) returns Bool is export {

  my @c_struct_list = %types.keys;
  my @nc_struct_list = %types.values;
  my $ret = True;
  
  #for @nc_struct_list -> $t {
  #  say nativesizeof($t);
  #}
  $c_header = "";
  for @cheaders -> $s {
    $c_header ~= "#include <$s>\n";
  }
  my $cprintf = '"';
  my @t;
  for @c_struct_list -> $s {
    $cprintf ~= "%d,";
    @t.push("sizeof($s)");
  }
  $cprintf = $cprintf.chop;
  $cprintf ~= '",' ~ @t.join(',');
  
  my $c = q:c:to/END_C/;
  #include <stdio.h>
  {$c_header}
  END_C
  $c ~= 'int main(int ac, char *ag[]) {';
  $c ~= q:c:to/END_C/;
    printf({$cprintf});
    return 0;
  END_C
  $c ~= '}';
  
  my $proc = compile_c($c, @clibs);
  my @c_size = $proc.out.get.split(',');
  #require ::($modulename);
  for (@nc_struct_list Z @c_size).flat -> $nctype, $csize {
    my $ncsize = nativesizeof($nctype);
    my $ctypename;
      for %types.kv -> $k, $v {
        {$ctypename = $k; last} if $v ~~ $nctype;
      }
    if ($ncsize ne $csize) {
      $ret = False;
      say "Size in Perl6 is not the same that the C one for : {$nctype.^name} -- C size : $csize ; NC size : $ncsize";
      diag-struct($ctypename, $nctype, :cheaders(@cheaders), :clibs(@clibs));
    } else {
      say "Size matched for P6:{$nctype.^name} - C:$ctypename";
    }
       
  }
  return $ret;
}

sub	diag-struct ($ctypename, $nctype, :@cheaders, :@clibs = ()) returns Bool is export {
      say "Compiling a test file, this assume field names are the same";
      my $cprintf = '"%d,';
      say "Perl6 name : {$nctype.^name}, C Name : $ctypename\n";
      my @t1 = "sizeof($ctypename)";
      for $nctype.^attributes -> $attr {
        $cprintf ~= "%d,";
        @t1.push("sizeof(piko.{$attr.name.substr(2)})")
      }
      my $ncsize = nativesizeof($nctype);
      $cprintf = $cprintf.chop;
      $cprintf ~= '",' ~ @t1.join(',');
      my $c = q:c:to/END_C/;
      #include <stdio.h>
      {$c_header}
      END_C
      $c ~= 'int main(int ac, char *ag[]) {';
      $c ~= q:c:to/END_C/;
      {$ctypename} piko;
      printf({$cprintf});
      return 0;
      END_C
      $c ~= '}';
      my $proc = compile_c($c, @clibs);
      my @c_size = $proc.out.get.split(',');
      my $scsize = @c_size.shift;
      my $totalc = 0;
      my $totalnc = 0;
      for ($nctype.^attributes Z @c_size).flat -> $attr, $csize {
        my $psize;
        my $has =  $attr.inlined ?? 'HAS' !! 'has';
        if !$attr.inlined and $attr.type.REPR eq 'CStruct' {
          $psize = nativesizeof(OpaquePointer);
        } else {
          $psize = nativesizeof($attr.type)
        }
        my $S = '';
        $S = 'DONT MATCH' if $psize ne $csize;
        say "For   $has {$attr.type.^name} "~$attr.name.substr(2)~" : c-size=$csize / nc-size="~$psize~" $S";
        $totalc += $csize;
        $totalnc += $psize;
      }
      say "Size given by sizeof and nativesizeof : C:$scsize/NC:$ncsize";
      say "Calculated total sizes : C:$totalc/NC:$totalnc";
      return True;
  }

sub     compile_c($c, @clibs) {
  my ($cfilename, $cfileh) =  tempfile("********.c");
  $cfileh.print($c);
  my ($execfilename, $execfileh) =  tempfile;
  $execfileh.close();
  #my $execfilename = "piko.exe";
  #run 'cp', '/root/piko.exe', $execfilename;
  run 'cc', $cfilename, '-o', $execfilename, @clibs;
  return run $execfilename, :out;
}


}
