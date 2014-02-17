package Ebooksforlib::Err;

use POSIX 'strftime';
use base 'Exporter';

our @EXPORT = qw(
  &errmsg
  &errinit
  &errexit
);

my %errcodes = ();

sub errcode{
  my $err = shift @_;
  ($p, $fn, $ln) = caller(1);
  $err = $fn.':'.$ln.' '.$err;
  $errcodes{$err}[1] = strftime('%d-%b-%Y %H:%M',localtime);
  return $errcodes{$err}[0] if($errcodes{$err}[0]);
  $errcodes{$err} = [++$errtop, strftime('%d-%b-%Y %H:%M',localtime)]; 
  return $errcodes{$err}->[0];
}

sub errinit{
  my $errfile = '/home/ebokdev/error.txt'; # config->{'errlog'};
  open my $fh, '<', $errfile or return; 
  while ( my $line = <$fh> ){
    my ($date,$code,$err) = split(';', $line);
    unless($errcodes{$err}[0]) {
      $errcodes{$err} = [$code, $date]; 
      $errtop = $code > $errtop ? $code : $errtop;
    } 
  }
}

sub errexit{
  my $errfile = '/home/ebokdev/error.txt'; # config->{'errlog'};
  open my $fh, '>', $errfile or return; 
  foreach my $err (sort {$errcodes{$a}[0] <=> $errcodes{$b}[0]} keys %errcodes){
    print $fh $errcodes{$err}[1].";".$errcodes{$err}[0].";".$err.";\n" if($errcodes{$err}[1]);
  }
}

sub errmsg{
  return "Error no: ".errcode(shift @_);
}

return 1;
