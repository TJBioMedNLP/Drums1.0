use strict;
use LWP::Simple;
use Mail::Sendmail;

use Log::Log4perl::Appender::File;

use XML::Simple;
use Data::Dumper;
use DBI;

my $flog = Log::Log4perl::Appender::File->new(
      filename  => 'mapMutationToUniprot.log',
      mode      => 'append',
      autoflush => 1,
      umask     => 0222,
    );
my $message = &GetCurrentTimeDate();
$flog->log(message => $message."\n");