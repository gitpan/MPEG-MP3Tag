package MPEG::MP3Tag;
use strict;
use Carp;
use vars qw(@ISA @EXPORT $VERSION @mp3_genres %mp3_genres);
@ISA = qw(Exporter);
@EXPORT = qw(set_mp3tag get_mp3tag);
$VERSION = '0.03';

{
  my $c = -1;
  %mp3_genres = map {($_, ++$c, lc($_), $c)} @mp3_genres;
}

=pod

=head1 NAME

MPEG::MP3Tag - Manipulate / fetch TAG info from a MPEG 2 Layer III
audio file.

=head1 SYNOPSIS

    #!perl -w
    use MPEG::MP3Tag;
    set_mp3tag('Pearls_Before_Swine.mp3', 'Pearls Before Swine', q"77's",
      'Sticks and Stones', '1990', q"(c) 1990 77's LTD.", 'rock & roll');
    my $tag = get_mp3tag('Pearls_Before_Swine.mp3');
    $tag->{GENRE} = 'rock';
    set_mp3tag('Pearls_Before_Swine.mp3', $tag);

=head1 DESCRIPTION

=cut

sub set_mp3tag {

=pod

=item set_mp3tag (FILE, TITLE, ARTIST, ALBUM, YEAR, COMMENT, GENRE)

=item set_mp3tag (FILE, $HASHREF)

Adds/changes tag information in an MP3 audio file.  Will clobber
any existing information in file.  All fields have a 30-byte limit,
except for YEAR, which has a four-byte limit.

GENRE is a case-insensitive text string representing a genre found
in C<@mp3_genres>.

Will accept either a list of values, or a hashref of the type
returned by C<get_mp3tag>.

=cut

    my($file, $title, $artist, $album, $year, $comment, $genre, $oldfh) = @_;

    if ('HASH' eq ref($title)) {
        ($title, $artist, $album, $year, $comment, $genre) = 
          (@$title{qw(TITLE ARTIST ALBUM YEAR COMMENT GENRE)});
    }

    $file ||= croak('No file specified');
    foreach ($title, $artist, $album, $comment) {
        $_ ||= '';
        if ($^W && length($_) > 30) {
            carp('Data too long for field; truncated');
        }
    }
    $year ||= '';
    if ($^W && length($year) > 4) {
        carp('Data too long for field; truncated');
    }

    warn "Genre $genre does not exist\n" if $^W && $genre && !exists($mp3_genres{$genre});

    open(FILE, "+<$file") or croak($!);
    $oldfh = select(FILE);
    seek(FILE, -128, 2);
    while (<FILE>) {
        if (/^TAG/) {
            seek(FILE, -128, 2);
        } else {
            seek(FILE, 0, 2);
        }
        last;
    }
#    print STDERR "Title: $title\nArtist: $artist\nAlbum: $album\nYear: $year\nComment: $comment\n";
    printf("TAG%-30.30s%-30.30s%-30.30s%-4.4s%-30.30s%-1.1s",
        $title, $artist, $album, $year, $comment, 
        ($genre && exists($mp3_genres{$genre})) ? chr($mp3_genres{$genre}) : "\021"
    );

    select($oldfh);
    close(FILE);
    1;
}

sub get_mp3tag {

=pod

=item get_mp3tag (FILE)

Returns hash reference containing tag information in MP3 file.  Same info
as described in C<set_mp3tag>.

=cut

    my($file, $tag, %info, @array) = @_;
    $file ||= croak('No file specified');
    open(FILE, "<$file") or croak($!);
    seek(FILE, -128, 2);
    while(<FILE>) {$tag .= $_}

    return if $tag !~ /^TAG/;
    $tag =~ /^TAG(.{30})(.{30})(.{30})(.{4})(.{30})(.)$/s; #;;
    %info = (
        TITLE => $1,
        ARTIST => $2,
        ALBUM => $3,
        YEAR => $4,
        COMMENT => $5,
        GENRE => $mp3_genres[ord($6)],
    );

    foreach (keys %info) {
        $info{$_} =~ s/\s+$//;
    }
    close(FILE);
    return {%info};
}

BEGIN { 
  @mp3_genres = (
    'Blues',
    'Classic Rock',
    'Country',
    'Dance',
    'Disco',
    'Funk',
    'Grunge',
    'Hip-Hop',
    'Jazz',
    'Metal',
    'New Age',
    'Oldies',
    'Other',
    'Pop',
    'R&B',
    'Rap',
    'Reggae',
    'Rock',
    'Techno',
    'Industrial',
    'Alternative',
    'Ska',
    'Death Metal',
    'Pranks',
    'Soundtrack',
    'Euro-Techno',
    'Ambient',
    'Trip-Hop',
    'Vocal',
    'Jazz+Funk',
    'Fusion',
    'Trance',
    'Classical',
    'Instrumental',
    'Acid',
    'House',
    'Game',
    'Sound Clip',
    'Gospel',
    'Noise',
    'AlternRock',
    'Bass',
    'Soul',
    'Punk',
    'Space',
    'Meditative',
    'Instrumental Pop',
    'Instrumental Rock',
    'Ethnic',
    'Gothic',
    'Darkwave',
    'Techno-Industrial',
    'Electronic',
    'Pop-Folk',
    'Eurodance',
    'Dream',
    'Southern Rock',
    'Comedy',
    'Cult',
    'Gangsta',
    'Top 40',
    'Christian Rap',
    'Pop/Funk',
    'Jungle',
    'Native American',
    'Cabaret',
    'New Wave',
    'Psychadelic',
    'Rave',
    'Showtunes',
    'Trailer',
    'Lo-Fi',
    'Tribal',
    'Acid Punk',
    'Acid Jazz',
    'Polka',
    'Retro',
    'Musical',
    'Rock & Roll',
    'Hard Rock',
  );
}

__END__

=pod

=head1 AUTHOR AND COPYRIGHT

Chris Nandor F<E<lt>pudge@pobox.comE<gt>>
http://pudge.net/

Copyright (c) 1998 Chris Nandor.  All rights reserved.  This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself.  Please see the Perl Artistic License.

Thanks to Johann Lindvall for his mp3tool program:

    http://www.dtek.chalmers.se/~d2linjo/mp3/mp3tool.html

Helped me figure it all out.

=head1 VERSION

v0.03, Tuesday, September 8, 1998

=cut
