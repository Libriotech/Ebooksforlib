package Ebooksforlib::San;

use CGI;

sub sanList
{
  my @out = ();
  foreach (@_)
  {
    my %r = %_;
    $r{'name'} = CGI::escapeHTML($_->{'name'});
    push @out, {%r};
#    print "\n",$r{'name'};
  }
  return @out;
};

return 1;
