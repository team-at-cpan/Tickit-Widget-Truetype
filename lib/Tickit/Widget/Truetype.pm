package Tickit::Widget::Truetype;
# ABSTRACT: Truetype font rendering for Tickit
use strict;
use warnings;

use parent qw(Tickit::Widget);

our $VERSION = '0.001';

=head1 NAME

Tickit::Widget::Truetype -

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Imager;
use Imager::Font;
use POSIX qw(ceil);
use List::Util qw(max);

use Tickit::RenderBuffer;

use constant { WIDTH => 128, HEIGHT => 128 };

use constant BLOCKS =>
	map chr,
		ord(' '),
		0x2596,  # 0001
		0x2597,  # 0010
		0x2584,  # 0011
		0x2598,  # 0100
		0x258c,  # 0101
		0x259a,  # 0110
		0x2599,  # 0111
		0x259d,  # 1000
		0x259e,  # 1001
		0x2590,  # 1010
		0x259f,  # 1011
		0x2580,  # 1100
		0x259b,  # 1101
		0x259c,  # 1110
		0x2588,  # 1111
	;

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	$self
}

sub render_to_rb {
	my ($self, $rb, $rect) = @_;

	my %args;
	$args{size} ||= 12;
	my $txt = $args{text} // 'test';
	my $top = $args{top} || 0;
	my $left = $args{left} || 0;
	my $pen = $args{pen} || Tickit::Pen->new(fg => 'white');
	foreach my $ch (split //, $txt) {
		my $data = $self->character($ch => $args{size});
		my $w = max(0, $data->{x_offset});
		my $y = $top;
		$rc->text_at($y++, $left + $w, $_, $pen) for @{$data->{data}};
		$left += $data->{advance};
	}
}

sub font_size { shift->{font_size} }

sub set_font {
	my $self = shift;
	delete $self->{font};
	$self->{font}{file} = shift;
	$self;
}

sub font { shift->{font}{file} }

sub character {
	my $self = shift;
	my $char = shift;
	my $size = (0+shift) || 12;
	return $self->{character}{$size}{$char} if exists $self->{character}{$size}{$char};

	$self->{font}{$size} = Imager::Font->new(file => $self->font, size => $size) or die 'error'
		unless $self->{font}{$size};
	my $font = $self->{font}{$size};
	my $white = Imager::Color->new('#FFFFFF');
	my $im = Imager->new(xsize => WIDTH, ysize => HEIGHT, channels => 1) or die Imager->errstr;
	my $bounds = $font->bounding_box(string => $char);
	$im->string(
		font => $font,
		text => $char,
		x => -$bounds->neg_width,
		y => $bounds->global_ascent,
		color => $white,
		aa => 0
	);

	my @rows;
	foreach my $y (map $_ * 2, 0..($bounds->font_height / 2)) {
		my @line = $im->getscanline(y => $y, x => 0, width => WIDTH);
		my @next = $im->getscanline(y => 1 + $y, x => 0, width => WIDTH);
		my $row = '';
		for my $x (map $_ * 2, 0..ceil($bounds->display_width/2) - 1) {
			# Calculating the correct 1/4 char here means we just end up with ->print,
			# but we lose the ability to do half-pixel alignment in output strings and
			# that also restricts our rendering options (ASCII fallback, for example).
			# So, this is probably in the wrong place.
			my @cell = map +($_->hsv)[2], $line[$x + 1], $line[$x], $next[$x + 1], $next[$x];
			my $v = 0;
			$v = ($v << 1) | $_ for @cell;
			$row .= (BLOCKS)[$v];
		}
		push @rows, $row;
	}
	$self->{character}{$char} = {
		x_offset => $bounds->neg_width,
		y_offset => $bounds->global_ascent,
		cols => ($bounds->display_width & 1) | ($bounds->display_width >> 1),
		advance => ($bounds->advance_width & 1) | ($bounds->advance_width >> 1),
		data => \@rows,
	};
}

1;

__END__

=head1 SEE ALSO

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011-2014. Licensed under the same terms as Perl itself.

