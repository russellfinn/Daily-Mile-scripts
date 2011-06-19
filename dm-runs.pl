#!/usr/bin/perl

# Get the entries of type Running for 2011 and print the date plus
# cumulative distance to stdout

# See the end of the file for an example entry

# To get the JSON and Modern::Perl packages on ubuntu do:
# sudo apt-get install libjson-perl libmodern-perl-perl
use Modern::Perl;
use JSON;
use LWP::Simple;
use Data::Dumper;

my $USERNAME = 'finnr';
if( defined $ARGV[0] ){ $USERNAME = $ARGV[0] }

my $CHATTY = 1;
if( defined $ARGV[1] ){ $CHATTY = $ARGV[1] }

main();

sub main
{
  my @myruns = ();
  getMyRuns(   \@myruns );
  printMyRuns( \@myruns );
}

sub getMyRuns
{
  my ( $myruns ) = @_;
  
  # Date ranges don't seem to work at the moment so instead we pull pages
  # until we hit the end of the previous year
  my $pageNumber = 0;

  my $baseUrl = "http://api.dailymile.com/people/$USERNAME/entries.json";
  my $pages_left = 1;
  my $fullUrl;
  
  # Read pages one at time until we reach the end, or hit last year
  while ( $pages_left )
  {
    $pageNumber++;

    # Build the full URL for the current page
    $fullUrl = $baseUrl . "?page=$pageNumber";
  
    my $data    = getEntries( $fullUrl );
    $pages_left = pagesLeft(  $data    );
  
    # Process the page
    if( $pages_left && defined $data )
    {
      ENTRIES: foreach my $entry ( @{ $data->{'entries'} } )
      {
        # print Dumper( $entry );    

        # See if we've gone past the start of the year  
        if( $entry->{'at'} =~ /2010/ )
        {
          $pages_left = 0;
          last ENTRIES;
        }
      
        if( $entry->{'workout'}{'activity_type'} eq 'Running' )
        { 
          my ( $date ) = ( $entry->{'at'} =~ /([0-9-]+)T/ ); 
          # msg( $date . "," . $entry->{'workout'}{'distance'}{'value'} );
      
          my %run =
          ( 
            'date'     => $date,
            'distance' =>  $entry->{'workout'}{'distance'}{'value'}
          );
      
          push @$myruns, \%run;
        }
      }
    }
    # dailymile API rules say no more than 1500 requests per hour
    # You could help obey this by using sleep calls...
    # sleep 1;
  }
}

sub printMyRuns
{
  my ( $runs ) = @_;
  my $total = 0;
    
  while( scalar( @$runs ) > 0 )
  {
    my $run = pop @$runs;
    $total += $run->{ 'distance' };
    say $run->{ 'date' } . "," . $total;
  }  
}

sub getEntries
{
  my $url = shift;

  msg( "Getting entries from $url " );

  # Use LWP::Simple::get() to get JSON data
  my $json_data = get( $url );
  die "Failed to get data from [$url]\n" unless defined $json_data;

  my $data = decode_json( $json_data );

  return $data;
}

# Return 1 if there are more pages to get for the user
sub pagesLeft
{
  my $response = shift;

  return 0 if( ! defined $response );

  if( scalar @{ $response->{'entries'} } == 0 )
  {
    return 0;
  }
  return 1;
}

sub msg
{
  my ( $l ) = @_;
  
  if( $CHATTY )
  {
	print "$l\n";  
  }	
}

# Here is a sample entry, once it's been parsed from the original JSON
# 'at' => '2011-06-15T12:27:13Z'
# 'comments' => ARRAY(0x93f5b30)
#	  empty array
# 'id' => 7764392
# 'likes' => ARRAY(0x93f5940)
#	  empty array
# 'location' => HASH(0x93f5960)
#	'name' => 'Winchester, GB'
# 'message' => 'My longest run of the year so far. The first 2 miles were with Paula, up to 3.5 with Andy Jones, who then turned back, then the rest with Dan Piccolo, Ian Craggs, Andy Perry and Peter Griffiths.  Andy had to walk up some of the hills in Ampfield Woods because he couldn\'t breathe.  I did an amount of doubling back for Andy'
# 'url' => 'http://www.dailymile.com/entries/7764392'
# 'user' => HASH(0x95b1e58)
#	'display_name' => 'Russell F.'
#	'photo_url' => 'http://s1.dmimg.com/pictures/users/121881/1281360706_avatar.jpg'
#	'url' => 'http://www.dailymile.com/people/finnr'
#	'username' => 'finnr'
# 'workout' => HASH(0x95b1eb8)
#	'activity_type' => 'Running'
#	'distance' => HASH(0x95b1ed8)
#	   'units' => 'miles'
#	   'value' => 10.17
#	'duration' => 5333
#	'felt' => 'good'
#	'title' => 'Farley Mount 10 miler'
